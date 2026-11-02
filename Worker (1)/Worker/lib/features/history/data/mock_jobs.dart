import '../domain/past_job.dart';

final mockPastJobs = <PastJob>[
  PastJob(
    id: 'job_110',
    serviceType: 'Electrician',
    customerName: 'Asha Rao',
    earnedPaise: 34900,
    completedAt: DateTime.now().subtract(const Duration(days: 1)),
    addressLine: '12 MG Road, Shivajinagar',
    areaCode: 'SHV',
    areaName: 'Shivajinagar',
  ),
  PastJob(
    id: 'job_109',
    serviceType: 'Plumber',
    customerName: 'Imran P',
    earnedPaise: 42000,
    completedAt: DateTime.now().subtract(const Duration(days: 6)),
    addressLine: '45 100 Feet Road, Indiranagar',
    areaCode: 'IND',
    areaName: 'Indiranagar',
  ),
  PastJob(
    id: 'job_108',
    serviceType: 'Carpenter',
    customerName: 'Sita N',
    earnedPaise: 89000,
    completedAt: DateTime.now().subtract(const Duration(days: 18)),
    addressLine: '8 Church Street, Richmond Town',
    areaCode: 'RCH',
    areaName: 'Richmond Town',
  ),
];
