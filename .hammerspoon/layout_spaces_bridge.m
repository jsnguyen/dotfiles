// Background Space transfer for Hammerspoon on macOS Tahoe.
// Adapted from franzbu's Hammerspoon PR #3889 (MIT); see layout_spaces_bridge.LICENSE.
// Loading this module does not move, focus, or activate anything.
#import <Cocoa/Cocoa.h>
#import <LuaSkin/lua.h>
#import <LuaSkin/lauxlib.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <dlfcn.h>
#import <stdint.h>
#import <string.h>

typedef int64_t (*PerformOperation)(void *operation);
static PerformOperation performOperation;
static const char *frameworkPath = "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight";
static const char *operationSymbol = "__ZL54SLSPerformAsynchronousBridgedWindowManagementOperationP47SLSAsynchronousBridgedWindowManagementOperation";

@interface NSObject (LayoutSpaceOperation)
- (instancetype)initWithWindows:(NSArray *)windows spaceID:(uint64_t)spaceID;
@end

// The operation is a local SkyLight symbol, so dlsym alone cannot resolve it.
static void *findOperation(void) {
    for (uint32_t image = 0; image < _dyld_image_count(); image++) {
        const char *name = _dyld_get_image_name(image);
        if (!name || strcmp(name, frameworkPath) != 0) continue;
        const struct mach_header_64 *header = (const struct mach_header_64 *)_dyld_get_image_header(image);
        if (header->magic != MH_MAGIC_64) return NULL;
        intptr_t slide = _dyld_get_image_vmaddr_slide(image);
        const struct segment_command_64 *linkedit = NULL;
        const struct symtab_command *symtab = NULL;
        const uint8_t *cursor = (const uint8_t *)(header + 1);
        for (uint32_t commandIndex = 0; commandIndex < header->ncmds; commandIndex++) {
            const struct load_command *command = (const struct load_command *)cursor;
            if (command->cmdsize < sizeof(*command)) return NULL;
            if (command->cmd == LC_SEGMENT_64) {
                const struct segment_command_64 *segment = (const struct segment_command_64 *)command;
                if (strncmp(segment->segname, SEG_LINKEDIT, sizeof(segment->segname)) == 0) linkedit = segment;
            }
            if (command->cmd == LC_SYMTAB) symtab = (const struct symtab_command *)command;
            cursor += command->cmdsize;
        }
        if (!linkedit || !symtab) return NULL;
        uintptr_t base = (uintptr_t)slide + linkedit->vmaddr - linkedit->fileoff;
        const char *strings = (const char *)(base + symtab->stroff);
        const struct nlist_64 *symbols = (const struct nlist_64 *)(base + symtab->symoff);
        for (uint32_t symbolIndex = 0; symbolIndex < symtab->nsyms; symbolIndex++) {
            uint32_t stringIndex = symbols[symbolIndex].n_un.n_strx;
            if (!stringIndex || stringIndex >= symtab->strsize) continue;
            if (strcmp(strings + stringIndex, operationSymbol) == 0) return (void *)((uintptr_t)slide + symbols[symbolIndex].n_value);
        }
    }
    return NULL;
}

static int failure(lua_State *L, const char *message) {
    lua_pushnil(L);
    lua_pushstring(L, message);
    return 2;
}

static Class operationClass(void) {
    Class type = NSClassFromString(@"SLSBridgedMoveWindowsToManagedSpaceOperation");
    return [type instancesRespondToSelector:@selector(initWithWindows:spaceID:)] ? type : Nil;
}

static int available(lua_State *L) {
    if (!performOperation) return failure(L, "This macOS build does not expose the background Space operation.");
    if (!operationClass()) return failure(L, "This macOS build does not expose the Space operation class.");
    lua_pushboolean(L, true);
    return 1;
}

static int moveWindow(lua_State *L) {
    lua_Integer window = luaL_checkinteger(L, 1);
    lua_Integer space = luaL_checkinteger(L, 2);
    luaL_argcheck(L, window > 0 && (uint64_t)window <= UINT32_MAX, 1, "expected a valid window ID");
    luaL_argcheck(L, space > 0, 2, "expected a valid Space ID");
    if (!performOperation || !operationClass()) return failure(L, "Background Space transfer is unavailable on this macOS build.");
    @autoreleasepool {
        @try {
            id operation = [[operationClass() alloc] initWithWindows:@[@((uint32_t)window)] spaceID:(uint64_t)space];
            if (!operation) return failure(L, "Could not create the Space transfer operation.");
            performOperation((__bridge void *)operation);
        } @catch (NSException *exception) {
            return failure(L, exception.reason.UTF8String ?: "Space transfer failed.");
        }
    }
    // Asynchronous submission only: Lua must verify hs.spaces.windowSpaces afterward.
    lua_pushboolean(L, true);
    return 1;
}

int luaopen_layout_spaces_bridge(lua_State *L) {
    dlopen(frameworkPath, RTLD_LAZY | RTLD_LOCAL);
    performOperation = (PerformOperation)findOperation();
    const luaL_Reg functions[] = {{"available", available}, {"move", moveWindow}, {NULL, NULL}};
    luaL_newlib(L, functions);
    return 1;
}
