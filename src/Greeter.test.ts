import { Effect, Exit } from "effect";
import { describe, expect, it } from "vitest";

import { GreetError, Greeter, GreeterLive } from "./Greeter.ts";

/** Provides the real Layer and runs to an `Exit`, success or failure alike. */
const run = <A, E>(effect: Effect.Effect<A, E, Greeter>) =>
  Effect.runPromiseExit(effect.pipe(Effect.provide(GreeterLive)));

describe("Greeter", () => {
  it("greets a valid name", async () => {
    const exit = await run(Effect.flatMap(Greeter, (greeter) => greeter.greet("world")));

    expect(exit).toStrictEqual(Exit.succeed("Hello, world!"));
  });

  it("fails on an empty name without throwing", async () => {
    const exit = await run(Effect.flatMap(Greeter, (greeter) => greeter.greet("   ")));

    // The error is a value carried by the Exit, not an exception: that is the
    // whole point of keeping it in the error channel.
    expect(exit).toStrictEqual(Exit.fail(new GreetError({ reason: "name is empty" })));
  });
});
