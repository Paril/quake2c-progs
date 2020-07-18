#pragma warning disable Q208 // we're valid darn you >:(
#pragma warning enable F302
#pragma warning disable Q205
#pragma warning disable F322
#pragma warning disable Q207
#pragma warning disable F306
#pragma target fte
//_9999

int(int, int) ModInt = #0:ModInt;

__variant(string) func_get = #0:func_get;

// function is visible to func_get and to the game code
#define API_FUNC __used