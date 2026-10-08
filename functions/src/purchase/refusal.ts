/** The store says no: unknown, forged, cancelled or foreign purchase. Not retryable. */
export class StoreRefusal extends Error {
  constructor(readonly reason: string) {
    super(reason);
  }
}
