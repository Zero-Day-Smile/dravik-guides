import 'package:get/get.dart';

import 'mission_event.dart';
import 'mission_state.dart';
import 'mission_state_machine.dart';

class MissionEngine extends GetxService {
  MissionEngine({MissionStateMachine? stateMachine})
      : _stateMachine = stateMachine ?? const MissionStateMachine();

  final MissionStateMachine _stateMachine;
  final Rx<MissionRuntimeState> runtime = MissionRuntimeState.initial().obs;

  MissionStatus get status => runtime.value.status;
  MissionContext get context => runtime.value.context;

  MissionTransition accept(MissionEvent event) {
    final transition = _stateMachine.apply(runtime.value, event);
    runtime.value = transition.state;
    return transition;
  }

  void reset({DateTime? now}) {
    runtime.value = MissionRuntimeState.initial(now: now);
  }
}
