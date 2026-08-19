import { Context, Data, Effect, Layer } from "effect";

/**
 * Domain error. `Data.TaggedError` builds an error class carrying a literal
 * `_tag` field: that is what lets `Effect.catchTag` single out one specific
 * error without `instanceof` or a chain of `if`s.
 *
 * It is never thrown — it travels through the Effect's error channel, where the
 * type system keeps it visible to the caller.
 */
export class GreetError extends Data.TaggedError("GreetError")<{
  readonly reason: string;
}> {}

/** The service contract, independent of any implementation. */
export interface GreeterService {
  readonly greet: (name: string) => Effect.Effect<string, GreetError>;
}

/**
 * The Tag: a typed key that names the service without providing it. Domain code
 * imports `Greeter`, never `GreeterLive` — that is what makes it testable by
 * swapping in a different Layer.
 *
 * The "app/Greeter" identifier is program-global: namespacing it avoids
 * collisions across packages.
 */
export class Greeter extends Context.Tag("app/Greeter")<Greeter, GreeterService>() {}

/**
 * The real implementation, wrapped in a Layer. `Layer.succeed` is enough when
 * construction needs neither an effect nor a dependency; otherwise reach for
 * `Layer.effect`.
 */
export const GreeterLive = Layer.succeed(Greeter, {
  greet: (name) =>
    name.trim() === ""
      ? Effect.fail(new GreetError({ reason: "name is empty" }))
      : Effect.succeed(`Hello, ${name}!`),
});
