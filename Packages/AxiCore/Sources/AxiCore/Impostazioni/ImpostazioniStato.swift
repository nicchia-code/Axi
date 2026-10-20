/// States of the `impostazioni` Machine.
///
/// The window is `chiuse` (closed, initial) or `aperte` (open). Opening an
/// already open window only brings it to the front and keeps the state.
public enum StatoImpostazioni: Sendable, Equatable {
    case chiuse
    case aperte

    /// Next state for a `utente` Event, following the Transitions of the Model.
    public func dopo(_ evento: EventoUtente) -> StatoImpostazioni {
        switch (self, evento) {
        case (_, .apreImpostazioni):
            .aperte
        case (.aperte, .chiudeImpostazioni), (.chiuse, .chiudeImpostazioni), (.aperte, .riapreAxi):
            .chiuse
        default:
            self
        }
    }
}
