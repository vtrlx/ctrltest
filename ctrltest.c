/* ctrltest.c — support library for Control Tester */

#include <lua.h>

#include <lualib.h>
#include <lauxlib.h>

#ifndef DEVEL
#define APP_ID "ca.vlacroix.ControlTester"
#else
#define APP_ID "ca.vlacroix.ControlTester.Devel"
#endif
#define APP_VER "0.1"

static int
lua_get_is_devel(lua_State *L)
{
#ifdef DEVEL
	lua_pushboolean(L, 1);
#else
	lua_pushboolean(L, 0);
#endif
	return 1;
}

static int
lua_get_app_id(lua_State *L)
{
	lua_pushstring(L, APP_ID);
	return 1;
}

static int
lua_get_app_ver(lua_State *L)
{
	lua_pushstring(L, APP_VER);
	return 1;
}

static const luaL_Reg ctrltestlib[] = {
	{ "get_is_devel", lua_get_is_devel },
	{ "get_app_id", lua_get_app_id },
	{ "get_app_ver", lua_get_app_ver },
	{ NULL, NULL },
};

extern char _binary_ctrltest_bytecode_start[];
extern char _binary_ctrltest_bytecode_end[];

int
main()
{
	lua_State *L;
	size_t ctrltest_bytecode_len;
	int lua_result;

	L = luaL_newstate();
	luaL_openlibs(L);
	lua_getglobal(L, "package");
	lua_getfield(L, -1, "loaded");
	lua_remove(L, -2);
	lua_pushstring(L, "ctrltestlib");
	luaL_newlib(L, ctrltestlib);
	lua_settable(L, -3);
	lua_remove(L, -1);

	ctrltest_bytecode_len = ((size_t)_binary_ctrltest_bytecode_end) - ((size_t)_binary_ctrltest_bytecode_start);

	lua_result = luaL_loadbuffer(L, _binary_ctrltest_bytecode_start, ctrltest_bytecode_len, APP_ID);
	switch (lua_result) {
	case LUA_OK:
		lua_call(L, 0, 0);
		return 0;
	default:
		/* FIXME: Handle each error case individually. */
		fprintf(stderr, "An unrecoverable error occurred when loading Control Tester, preventing the program from starting.\n");
		return lua_result;
	}
}
