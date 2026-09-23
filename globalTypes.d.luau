-- Global type declarations for luau-lsp (see .vscode/settings.json -> luau-lsp.types.definitionFiles).
-- Roblox API globals (game, workspace, Instance, ...) are provided automatically by luau-lsp itself.
-- This file only adds globals luau-lsp cannot know about: the TestEz test-runner functions
-- injected into every *.spec.luau file at runtime (see selene.toml's `roblox+testez` std for the linter side).

-- Mirrors Packages/_Index/roblox_testez@0.4.1/testez/src/Expectation.lua.
-- All matcher fields (a/an/ok/equal/near/throw) are plain function values, not methods:
-- TestEz's `bindSelf` lets them be called with either `:` or `.`, and every spec in this
-- project uses the `.` chain (`expect(x).to.equal(y)`), so these must NOT take a `self` param
-- - declaring one makes Luau bind the first real argument to `self` and misreport its type.
export type TestEzExpectationChain = {
	-- SELF_KEYS: readability-only, just return the same chain
	to: TestEzExpectationChain,
	be: TestEzExpectationChain,
	been: TestEzExpectationChain,
	have: TestEzExpectationChain,
	was: TestEzExpectationChain,
	at: TestEzExpectationChain,
	-- NEGATION_KEYS: returns an inverted chain
	never: TestEzExpectationChain,
	-- matchers
	a: (typeName: string) -> TestEzExpectationChain,
	an: (typeName: string) -> TestEzExpectationChain,
	ok: () -> TestEzExpectationChain,
	equal: (value: any) -> TestEzExpectationChain,
	near: (value: number, limit: number?) -> TestEzExpectationChain,
	throw: (message: string?) -> TestEzExpectationChain,
}

declare function expect(value: any): TestEzExpectationChain

declare function describe(phrase: string, callback: () -> ()): ()
declare function describeFOCUS(phrase: string, callback: () -> ()): ()
declare function describeSKIP(phrase: string, callback: () -> ()): ()

declare function it(phrase: string, callback: () -> ()): ()
declare function itFOCUS(phrase: string, callback: () -> ()): ()
declare function itSKIP(phrase: string, callback: () -> ()): ()
declare function itFIXME(phrase: string, callback: () -> ()): ()

declare function beforeEach(callback: () -> ()): ()
declare function afterEach(callback: () -> ()): ()
declare function beforeAll(callback: () -> ()): ()
declare function afterAll(callback: () -> ()): ()

declare function FOCUS(): ()
declare function SKIP(): ()
declare function FIXME(reason: string?): ()
