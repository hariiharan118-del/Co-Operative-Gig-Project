/// Worker-facing job lifecycle. The primary CTA is derived from this value
/// so screens never duplicate "what happens next" logic.
enum JobLifecycleStatus {
  assigned,
  enRoute,
  arrived,
  inProgress,
  awaitingPayment,
  completed,
}

/// Label + next status + API path for the single full-width job button.
class JobPrimaryAction {
  const JobPrimaryAction({
    required this.labelKey,
    required this.nextStatus,
    required this.apiPath,
    this.opensNativeMaps = false,
  });

  final String labelKey;
  final JobLifecycleStatus nextStatus;

  /// Endpoint to call when this action is taken (relative to the job id).
  final String apiPath;
  final bool opensNativeMaps;
}

extension JobLifecycleStatusX on JobLifecycleStatus {
  /// Central mapping: current status → next primary action.
  JobPrimaryAction? get primaryAction => switch (this) {
        JobLifecycleStatus.assigned => const JobPrimaryAction(
            labelKey: 'job.actionNavigate',
            nextStatus: JobLifecycleStatus.enRoute,
            apiPath: '/navigate',
            opensNativeMaps: true,
          ),
        JobLifecycleStatus.enRoute => const JobPrimaryAction(
            labelKey: 'job.actionArrived',
            nextStatus: JobLifecycleStatus.arrived,
            apiPath: '/arrive',
          ),
        JobLifecycleStatus.arrived => const JobPrimaryAction(
            labelKey: 'job.actionStart',
            nextStatus: JobLifecycleStatus.inProgress,
            apiPath: '/start',
          ),
        JobLifecycleStatus.inProgress => const JobPrimaryAction(
            labelKey: 'job.actionComplete',
            nextStatus: JobLifecycleStatus.awaitingPayment,
            apiPath: '/complete',
          ),
        JobLifecycleStatus.awaitingPayment => null,
        JobLifecycleStatus.completed => null,
      };

  String get labelKey => switch (this) {
        JobLifecycleStatus.assigned => 'job.statusAssigned',
        JobLifecycleStatus.enRoute => 'job.statusEnRoute',
        JobLifecycleStatus.arrived => 'job.statusArrived',
        JobLifecycleStatus.inProgress => 'job.statusInProgress',
        JobLifecycleStatus.awaitingPayment => 'job.statusAwaitingPayment',
        JobLifecycleStatus.completed => 'job.statusCompleted',
      };

  /// ACCEPTED / en-route — ping live location until the worker arrives.
  bool get shouldPingLocation =>
      this == JobLifecycleStatus.assigned || this == JobLifecycleStatus.enRoute;

  bool get isOpen =>
      this != JobLifecycleStatus.completed;

  /// Backend `BookingStatus` value for PATCH /bookings/:id/status.
  String get apiName => switch (this) {
        JobLifecycleStatus.assigned => 'ACCEPTED',
        JobLifecycleStatus.enRoute => 'EN_ROUTE',
        JobLifecycleStatus.arrived => 'ARRIVED',
        JobLifecycleStatus.inProgress => 'IN_PROGRESS',
        JobLifecycleStatus.awaitingPayment => 'AWAITING_PAYMENT',
        JobLifecycleStatus.completed => 'COMPLETED',
      };

  int get progressRank => switch (this) {
        JobLifecycleStatus.assigned => 0,
        JobLifecycleStatus.enRoute => 1,
        JobLifecycleStatus.arrived => 2,
        JobLifecycleStatus.inProgress => 3,
        JobLifecycleStatus.awaitingPayment => 4,
        JobLifecycleStatus.completed => 5,
      };
}

JobLifecycleStatus? jobLifecycleFromApi(Object? raw) {
  return switch ('${raw ?? ''}'.toUpperCase()) {
    'ACCEPTED' || 'ASSIGNED' => JobLifecycleStatus.assigned,
    'EN_ROUTE' || 'ENROUTE' => JobLifecycleStatus.enRoute,
    'ARRIVED' => JobLifecycleStatus.arrived,
    'IN_PROGRESS' || 'INPROGRESS' => JobLifecycleStatus.inProgress,
    'AWAITING_PAYMENT' || 'AWAITINGPAYMENT' =>
      JobLifecycleStatus.awaitingPayment,
    'COMPLETED' => JobLifecycleStatus.completed,
    _ => null,
  };
}

bool isOpenBookingStatus(Object? raw) {
  return switch ('${raw ?? ''}'.toUpperCase()) {
    'ACCEPTED' ||
    'ASSIGNED' ||
    'EN_ROUTE' ||
    'ENROUTE' ||
    'ARRIVED' ||
    'IN_PROGRESS' ||
    'INPROGRESS' ||
    'AWAITING_PAYMENT' ||
    'AWAITINGPAYMENT' =>
      true,
    _ => false,
  };
}

class ActiveJob {
  const ActiveJob({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.jobType,
    required this.farePaise,
    required this.lat,
    required this.lng,
    required this.status,
    this.distanceKm = 1.8,
    this.etaMinutes = 9,
    this.notes,
  });

  final String id;
  final String customerName;
  final String customerPhone;
  final String jobType;
  final int farePaise;
  final double lat;
  final double lng;
  final JobLifecycleStatus status;
  final double distanceKm;
  final int etaMinutes;
  final String? notes;

  JobPrimaryAction? get primaryAction => status.primaryAction;

  ActiveJob copyWith({
    JobLifecycleStatus? status,
    double? distanceKm,
    int? etaMinutes,
  }) {
    return ActiveJob(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      jobType: jobType,
      farePaise: farePaise,
      lat: lat,
      lng: lng,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      notes: notes,
    );
  }
}
