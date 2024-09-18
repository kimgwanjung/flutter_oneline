import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oneline2/admin_list/feature/page8_Calendar/models/event_model.dart';
import 'package:oneline2/admin_list/feature/page8_Calendar/view_models/calendar_event.dart';
import 'package:oneline2/admin_list/feature/page8_Calendar/view_models/calendar_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final Map<DateTime, List<Event>> _events = {};

  EventBloc() : super(EventInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<LoadEventsForDay>(_onLoadEventsForDay);
    on<AddEvent>(_onAddEvent);
    on<RemoveEvent>(_onRemoveEvent);
    on<UpdateEvent>(_onUpdateEvent);
  }

  void _onLoadEvents(LoadEvents event, Emitter<EventState> emit) {
    emit(EventLoadInProgress());
    try {
      final allEvents = _events.values.expand((e) => e).toList();
      emit(EventLoadSuccess(allEvents));
    } catch (e) {
      emit(EventLoadFailure(e.toString()));
    }
  }

  void _onLoadEventsForDay(LoadEventsForDay event, Emitter<EventState> emit) {
    emit(EventLoadInProgress());
    try {
      final selectedDay = DateTime(event.selectedDay.year,
          event.selectedDay.month, event.selectedDay.day);
      final eventsForDay = _events[selectedDay] ?? [];
      emit(EventLoadSuccess(eventsForDay));
    } catch (e) {
      emit(EventLoadFailure(e.toString()));
    }
  }

  void _onAddEvent(AddEvent event, Emitter<EventState> emit) {
    emit(EventLoadInProgress());
    try {
      final newEvent = event.event;
      final startDate = DateTime(newEvent.startTime.year,
          newEvent.startTime.month, newEvent.startTime.day);
      final endDate = DateTime(
          newEvent.endTime.year, newEvent.endTime.month, newEvent.endTime.day);

      final dateRange = Iterable.generate(
        endDate.difference(startDate).inDays + 1,
        (i) => startDate.add(Duration(days: i)),
      );

      for (final date in dateRange) {
        _events.putIfAbsent(date, () => []);
        _events[date]!.add(newEvent);
      }

      final allEvents = _events.values.expand((e) => e).toList();
      emit(EventLoadSuccess(allEvents));
    } catch (e) {
      emit(EventLoadFailure(e.toString()));
    }
  }

  void _onRemoveEvent(RemoveEvent event, Emitter<EventState> emit) {
    emit(EventLoadInProgress());
    try {
      final eventToRemove = event.event;
      final startDate = DateTime(eventToRemove.startTime.year,
          eventToRemove.startTime.month, eventToRemove.startTime.day);
      final endDate = DateTime(eventToRemove.endTime.year,
          eventToRemove.endTime.month, eventToRemove.endTime.day);

      final dateRange = Iterable.generate(
        endDate.difference(startDate).inDays + 1,
        (i) => startDate.add(Duration(days: i)),
      );

      for (final date in dateRange) {
        _events[date]?.removeWhere((e) => e.id == eventToRemove.id);
      }

      final allEvents = _events.values.expand((e) => e).toList();
      emit(EventLoadSuccess(allEvents));
    } catch (e) {
      emit(EventLoadFailure(e.toString()));
    }
  }

  void _onUpdateEvent(UpdateEvent event, Emitter<EventState> emit) {
    emit(EventLoadInProgress());
    try {
      final updatedEvent = event.updatedEvent;
      final startDate = DateTime(updatedEvent.startTime.year,
          updatedEvent.startTime.month, updatedEvent.startTime.day);
      final endDate = DateTime(updatedEvent.endTime.year,
          updatedEvent.endTime.month, updatedEvent.endTime.day);

      // 날짜 범위 생성
      final dateRange = Iterable.generate(
        endDate.difference(startDate).inDays + 1,
        (i) => startDate.add(Duration(days: i)),
      );

      for (final date in dateRange) {
        // 날짜에 맞는 인덱스 검색
        final index = _events[date]?.indexWhere((e) => e.id == updatedEvent.id);
        if (index != null && index != -1) {
          // 기존 이벤트 업데이트
          _events[date]?[index] = updatedEvent;
        } else {
          // 새 이벤트 추가
          _events.putIfAbsent(date, () => []).add(updatedEvent);
        }
      }

      // 모든 이벤트를 가져와서 상태 업데이트
      final allEvents = _events.values.expand((e) => e).toList();
      emit(EventLoadSuccess(allEvents));
    } catch (e) {
      emit(EventLoadFailure(e.toString()));
    }
  }
}
