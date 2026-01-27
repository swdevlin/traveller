# frozen_string_literal: true

LAW_LEVELS = [
  {
    code: 0,
    armour: 'No restrictions',
    weapons: 'No restrictions',
    economic_law: 'No contract law or licenses required',
    criminal_law: 'No formal legal system',
    private_law: 'No formal legal system',
    personal_law: 'No restrictions'
  },
  {
    code: 1,
    armour: 'Battle dress (C5)',
    weapons: 'Poison gas, explosives, undetectable weapons, weapons of mass destruction',
    economic_law: 'Optional registration of private agreements, claim registration',
    criminal_law: 'Grave and serious crimes prosecuted',
    private_law: 'Duelling restricted, contract law enforceable',
    personal_law: 'Speech risking physical harm (e.g., yelling fire in a crowded theatre) prohibited'
  },
  {
    code: 2,
    armour: 'Combat armour',
    weapons: 'Portable energy and laser weapons',
    economic_law: 'Registration of corporations, enforcement of claims',
    criminal_law: 'Moderate crimes prosecuted',
    private_law: 'Duelling prohibited',
    personal_law: 'Registration of identity, libel prohibited'
  },
  {
    code: 3,
    armour: 'Flak jackets and obvious armour (C4)',
    weapons: 'Military weapons (all portable heavy weapons)',
    economic_law: 'Basic permitting and zoning laws, required licensing of corporations and tax reporting, bankruptcy law',
    criminal_law: 'Minor crimes prosecuted',
    private_law: 'Private settlement of Moderate crimes prohibited',
    personal_law: 'Group-related regulations (e.g., drinking age)'
  },
  {
    code: 4,
    armour: 'Cloth armour (C3)',
    weapons: 'Light assault weapons and submachine guns (all fully automatic weapons)',
    economic_law: 'Registration of professional licenses, periodic random auditing of major financial transactions',
    criminal_law: 'Petty crimes prosecuted',
    private_law: 'Private settlement of all crimes prohibited',
    personal_law: 'Hate speech prohibited'
  },
  {
    code: 5,
    armour: 'Mesh armour',
    weapons: 'Personal concealable ranged weapons (auto pistols and revolvers)',
    economic_law: 'Required professional licenses for most skilled professions',
    criminal_law: 'Trivial crimes prosecuted',
    private_law: 'Public filing of all disputes and settlements',
    personal_law: 'Mandatory identification papers'
  },
  {
    code: 6,
    armour: '',
    weapons: 'All firearms except shotguns and stunners; carrying weapons discouraged',
    economic_law: 'Moderate permitting and zoning laws, registration fees required for professional licenses',
    criminal_law: 'Public surveillance',
    private_law: 'Government venue required for all settlements',
    personal_law: 'Public surveillance'
  },
  {
    code: 7,
    armour: 'C2',
    weapons: 'Shotguns and all other ranged firearms',
    economic_law: 'Professional licenses required for all skilled labour, periodic auditing of major financial transactions',
    criminal_law: 'Insignificant crimes prosecuted',
    private_law: 'Limits on all tort settlements',
    personal_law: '‘Offensive’ speech prohibited'
  },
  {
    code: 8,
    armour: 'All visible armour (C1)',
    weapons: 'All bladed weapons, stunners',
    economic_law: 'Restrictive zoning and permitting laws',
    criminal_law: 'Indefinite detention allowed',
    private_law: 'Government review of all settlements',
    personal_law: 'No right to protect personal data'
  },
  {
    code: 9,
    armour: 'All armour',
    weapons: 'All weapons, including knives longer than 10cm',
    economic_law: 'Active auditing of all financial transactions',
    criminal_law: 'No effective right to counsel',
    private_law: 'Government approval for all settlements',
    personal_law: '‘Subversive’ speech prohibited'
  },
  {
    code: 10,
    armour: 'All weapons violations are treated as Serious crimes',
    weapons: 'All weapons violations are treated as Serious crimes',
    economic_law: 'Arduous permitting and zoning laws',
    criminal_law: 'Pre-emptive detention allowed',
    private_law: 'Government adjudicated arbitration required',
    personal_law: 'Restrictions on movement and residency'
  },
  {
    code: 11,
    armour: 'Random sweeps for weapons violations',
    weapons: 'Random sweeps for weapons violations',
    economic_law: 'Continuous auditing of all financial transactions',
    criminal_law: 'Arbitrary indefinite detention allowed',
    private_law: 'Arbitrary government adjudication, government approval of all contracts',
    personal_law: 'Warrantless searches, government control of all information, routine surveillance of private activities'
  },
  {
    code: 12,
    armour: 'Active monitoring for ownership violations',
    weapons: 'Active monitoring for ownership violations',
    economic_law: 'All economic regulation enforcement transferred to criminal justice system',
    criminal_law: 'Arbitrary verdicts without defendant participation',
    private_law: 'All civil proceedings transferred to criminal justice system',
    personal_law: 'Unrestricted surveillance of private activities, group punishments'
  },
  {
    code: 13,
    armour: '',
    weapons: '',
    economic_law: '',
    criminal_law: 'Paramilitary law enforcement, thought crimes prosecuted',
    private_law: '',
    personal_law: ''
  },
  {
    code: 14,
    armour: '',
    weapons: '',
    economic_law: '',
    criminal_law: 'Fully-fledged police state, arbitrary executions or ‘disappearances’',
    private_law: '',
    personal_law: ''
  },
  {
    code: 15,
    armour: '',
    weapons: '',
    economic_law: '',
    criminal_law: 'Rigid control of daily life, gulag state',
    private_law: '',
    personal_law: ''
  },
  {
    code: 16,
    armour: '',
    weapons: '',
    economic_law: '',
    criminal_law: 'Thoughts controlled, disproportionate punishments',
    private_law: '',
    personal_law: ''
  },
  {
    code: 17,
    armour: '',
    weapons: '',
    economic_law: '',
    criminal_law: 'Legalised oppression',
    private_law: '',
    personal_law: ''
  },
  {
    code: 18,
    armour: '',
    weapons: '',
    economic_law: '',
    criminal_law: 'Routine oppression',
    private_law: '',
    personal_law: ''
  }
]
