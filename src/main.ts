import { Effect } from "effect";

import { GreeterLive, Greeter } from "./Greeter.ts";

/**
 * The program. Its type says everything it does:
 *
 *   Effect<void, GreetError, Greeter>
 *          ^     ^           ^
 *          |     |           +-- what it needs
 *          |     +-------------- how it can fail
 *          +-------------------- what it produces
 *
 * Nothing runs at construction time: `program` is an inert description.
 */
const program = Effect.gen(function* () {
  const greeter = yield* Greeter;
  const message = yield* greeter.greet("world");
  yield* Effect.log(message);
});

/**
 * The wiring, the only place that knows about the implementation.
 * `Effect.provide` discharges the `Greeter` requirement: the type's third
 * parameter drops back to `never`, and that is the condition that makes the
 * Effect runnable.
 *
 * `Effect.catchTag` handles the domain error exhaustively — removing this
 * branch would make `runPromise` fail to type-check.
 */
const runnable = program.pipe(
  Effect.provide(GreeterLive),
  Effect.catchTag("GreetError", (error) => Effect.logError(`Failed: ${error.reason}`)),
);

await Effect.runPromise(runnable);
