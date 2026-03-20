from pathlib import Path
import shutil
import sqlite3

def find_item_id(items, search_id):
    '''
    DESC: Useful to reduce the for loop depth by 1.
    '''
    for i in items:
        if i['itemID'] ==  search_id:
            return i

    return None

def main():

    zotero_path = Path.home() / 'Zotero' # typical zotero path
    collections = []

    # initialize sqlite database
    # database cannot be open in any other applications
    connection = sqlite3.connect(zotero_path / 'zotero.sqlite')
    cursor = connection.cursor()

    # get ALL the items in the database
    # not all of the items are pdf or file items
    # some of the items are just references to webpages etc
    # itemAttachments will tell you which item has a pdf attachement
    items = []
    sql_items = cursor.execute('SELECT itemID, key FROM items;')
    for row in sql_items.fetchall():
        i = {'itemID': row[0], 'key': row[1], 'parentItemID': None, 'contentType': None}
        items.append(i)

    # get ALL the attachments for all the items and add it to the previous dict
    sql_itemAttachments = cursor.execute('SELECT itemID, parentItemID, contentType FROM itemAttachments;')
    for row in sql_itemAttachments.fetchall():
        i = find_item_id(items, row[0])
        i['parentItemID'] = row[1]
        i['contentType'] = row[2]

    # get all the collection names
    sql_collections = cursor.execute('SELECT collectionName, collectionID, libraryID FROM collections;')
    for row in sql_collections.fetchall():
        if row[2] != 1:
            continue
        c = {'name': row[0], 'id': row[1]}
        collections.append(c)

    # initialize an array to hold all the items it references
    for c in collections:
        c['itemIDs'] = []

    # get all the ids of all the items that are referenced in the collection
    # these items will NOT be the attachments
    sql_collectionItems = cursor.execute('SELECT collectionID, itemID FROM collectionItems;')
    for row in sql_collectionItems.fetchall():
        for c in collections:
            if c['id'] == row[0]:
                c['itemIDs'].append(row[1])

    # sort the item ids and setup key array
    # the pdfs are stored in folders like: zotero/storage/<KEY>
    for c in collections:
        c['keys'] = []
        c['itemIDs'] = list(sorted(c['itemIDs']))


    # for each item in the collection, find the PARENT ITEM
    # the stored pdf will be in the folder corresponding to the key for the child item
    for c in collections:
        for itemID in c['itemIDs']:
            i = find_item_id(items, i['parentItemID'])
            for i in items:
                if itemID == i['parentItemID']:
                    child = find_item_id(items, i['itemID'])
                    c['keys'].append(child ['key'])


    # set up exporting, exports 
    export_folder = Path.home() / 'landing' / 'docs' / 'zotero_pdfs'
    #export_folder = Path('/Users/jsn/Library/Mobile Documents/3L68KQB4HG~com~readdle~CommonDocuments/Documents')

    for c in collections:

        # create a folder for each collection
        c_folder_path = export_folder / c['name']
        c_folder_path.mkdir(parents=True, exist_ok=True)

        # for each collection, copy the items pdfs
        for key in c['keys']:
            zotero_key_path = zotero_path / 'storage' / key
            pdf_files = list(zotero_key_path.glob('*.pdf'))

            if len(pdf_files) == 1:
                source= pdf_files[0]
                destination = c_folder_path / source.name
                print('{}\n{}\n'.format(source , destination))

                # WILL OVERWRITE HERE
                shutil.copy(source, destination)

    connection.close()

if __name__=='__main__':
    main()
