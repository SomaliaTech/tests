import '../../../../core/utils/typedefs.dart';
import '../entities/tracking.dart';
import '../repositories/tracking_repository.dart';

class GetTrackingInfo {
  final TrackingRepository repository;
  const GetTrackingInfo(this.repository);
  ResultFuture<TrackingInfo> call(String orderId) =>
      repository.getTrackingInfo(orderId);
}
