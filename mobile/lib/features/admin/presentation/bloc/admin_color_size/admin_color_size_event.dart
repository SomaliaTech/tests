import 'package:equatable/equatable.dart';

abstract class AdminColorSizeEvent extends Equatable {
  const AdminColorSizeEvent();
  @override
  List<Object?> get props => [];
}

// Colors Events
class FetchAllColorsEvent extends AdminColorSizeEvent {}

class CreateColorEvent extends AdminColorSizeEvent {
  final Map<String, dynamic> data;
  const CreateColorEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateColorEvent extends AdminColorSizeEvent {
  final String colorId;
  final Map<String, dynamic> data;
  const UpdateColorEvent(this.colorId, this.data);

  @override
  List<Object?> get props => [colorId, data];
}

class DeleteColorEvent extends AdminColorSizeEvent {
  final String colorId;
  const DeleteColorEvent(this.colorId);

  @override
  List<Object?> get props => [colorId];
}

// Sizes Events
class FetchAllSizesEvent extends AdminColorSizeEvent {}

class CreateSizeEvent extends AdminColorSizeEvent {
  final Map<String, dynamic> data;
  const CreateSizeEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateSizeEvent extends AdminColorSizeEvent {
  final String sizeId;
  final Map<String, dynamic> data;
  const UpdateSizeEvent(this.sizeId, this.data);

  @override
  List<Object?> get props => [sizeId, data];
}

class DeleteSizeEvent extends AdminColorSizeEvent {
  final String sizeId;
  const DeleteSizeEvent(this.sizeId);

  @override
  List<Object?> get props => [sizeId];
}
