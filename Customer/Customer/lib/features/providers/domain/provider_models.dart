enum ProviderQueueStatus { reviewNeeded, infoRequested, pendingReview, docsMissing }

class MarketplaceProvider {
  const MarketplaceProvider({
    required this.id,
    required this.name,
    required this.specialty,
    required this.category,
    required this.license,
    required this.status,
    required this.submittedLabel,
    required this.about,
    required this.skills,
    required this.jobsCompleted,
    required this.earningsLabel,
    required this.initials,
    this.verified = true,
    this.active = true,
  });

  final String id;
  final String name;
  final String specialty;
  final String category;
  final String license;
  final ProviderQueueStatus status;
  final String submittedLabel;
  final String about;
  final List<String> skills;
  final int jobsCompleted;
  final String earningsLabel;
  final String initials;
  final bool verified;
  final bool active;
}

const mockProviders = <MarketplaceProvider>[
  MarketplaceProvider(
    id: 'prv_sarah',
    name: 'Sarah Jenkins',
    specialty: 'Master Electrician',
    category: 'Electrical & Maintenance',
    license: 'EL-94821',
    status: ProviderQueueStatus.reviewNeeded,
    submittedLabel: '2h ago',
    about:
        'Licensed electrician with over 8 years of experience in residential and commercial wiring, fixture installation, and panel upgrades.',
    skills: [
      'Electrical Wiring',
      'Fixture Installation',
      'Troubleshooting',
      'Panel Upgrades',
    ],
    jobsCompleted: 41,
    earningsLabel: '₹1,28,400',
    initials: 'SJ',
  ),
  MarketplaceProvider(
    id: 'prv_marcus',
    name: 'Marcus Thorne',
    specialty: 'Master Electrician',
    category: 'Electrical & Maintenance',
    license: 'EL-10211',
    status: ProviderQueueStatus.pendingReview,
    submittedLabel: '5h ago',
    about:
        'Cooperative electrician focused on safe, same-day household repairs and certified panel work.',
    skills: ['Commercial Wiring', 'Panel Upgrades', 'Troubleshooting'],
    jobsCompleted: 32,
    earningsLabel: '₹4,250',
    initials: 'MT',
  ),
  MarketplaceProvider(
    id: 'prv_john',
    name: 'John Doe',
    specialty: 'HVAC Tech',
    category: 'AC Repair',
    license: 'HV-3301',
    status: ProviderQueueStatus.infoRequested,
    submittedLabel: 'Yesterday',
    about: 'HVAC technician. Some documents are still missing for verification.',
    skills: ['AC Repair', 'Gas Charging'],
    jobsCompleted: 12,
    earningsLabel: '₹36,000',
    initials: 'JD',
    verified: false,
    active: false,
  ),
];

MarketplaceProvider? providerById(String id) {
  for (final item in mockProviders) {
    if (item.id == id) return item;
  }
  return null;
}
