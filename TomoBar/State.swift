import SwiftState

typealias TBStateMachine = StateMachine<TBStateMachineStates, TBStateMachineEvents>

enum TBStateMachineEvents: EventType {
    case startStop, confirmedNext, skipEvent
    case intervalCompleted, sessionCompleted
}

enum TBStateMachineStates: StateType {
    case idle, work, shortRest, longRest
}
