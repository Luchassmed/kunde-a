// KUNDESPECIFIK TEST CASE — hører til kunde-a og ligger derfor her, ikke i common.
//
// Filer i denne mappe røres aldrig af en opdatering af det fælles repo. Uanset om
// common står på v1.0.0 eller v1.1.0, kører kundens egne tests uændret videre.
//
// Samme kontrakt som de basale test cases i common.

const pause = (ms) => new Promise((r) => setTimeout(r, ms));

module.exports = {
  id: 'kunde-a-rolle',
  navn: 'Rollen "Økonomi-læseadgang" kan anmodes',
  version: '1.0.0',
  severity: 'medium',
  forventet_varighed_ms: 1800,

  async run(ctx) {
    if (!ctx.mock) return { status: 'skipped', trin: [], note: 'Kun implementeret som mock i denne demo.' };

    await pause(140);
    return {
      status: 'pass',
      trin: [
        'Søg i rollekataloget efter "Økonomi-læseadgang"',
        'Rollen er synlig for standardbrugere',
        'Rollen kan lægges i kurven',
      ],
    };
  },
};
