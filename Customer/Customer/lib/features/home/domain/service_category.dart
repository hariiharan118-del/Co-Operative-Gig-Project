class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconName,
    required this.basePricePaise,
  });

  final String id;
  final String name;
  final String slug;
  final String iconName;
  final int basePricePaise;
}

const mockCategories = <ServiceCategory>[
  ServiceCategory(
    id: 'electrician',
    name: 'Electrician',
    slug: 'electrician',
    iconName: 'electrical_services',
    basePricePaise: 29900,
  ),
  ServiceCategory(
    id: 'plumber',
    name: 'Plumber',
    slug: 'plumber',
    iconName: 'plumbing',
    basePricePaise: 34900,
  ),
  ServiceCategory(
    id: 'carpenter',
    name: 'Carpenter',
    slug: 'carpenter',
    iconName: 'handyman',
    basePricePaise: 39900,
  ),
  ServiceCategory(
    id: 'ac_repair',
    name: 'AC Repair',
    slug: 'ac_repair',
    iconName: 'ac_unit',
    basePricePaise: 49900,
  ),
  ServiceCategory(
    id: 'painter',
    name: 'Painter',
    slug: 'painter',
    iconName: 'format_paint',
    basePricePaise: 59900,
  ),
  ServiceCategory(
    id: 'appliance',
    name: 'Appliance Repair',
    slug: 'appliance',
    iconName: 'kitchen',
    basePricePaise: 44900,
  ),
  ServiceCategory(
    id: 'pest',
    name: 'Pest Control',
    slug: 'pest',
    iconName: 'bug_report',
    basePricePaise: 79900,
  ),
  ServiceCategory(
    id: 'cleaning',
    name: 'House Cleaning',
    slug: 'cleaning',
    iconName: 'cleaning_services',
    basePricePaise: 39900,
  ),
];
