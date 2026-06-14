import '../../../../core/utils/typedefs.dart';
import '../entities/tracking.dart';

abstract class TrackingRepository {
  ResultFuture<TrackingInfo> getTrackingInfo(String orderId);
}
