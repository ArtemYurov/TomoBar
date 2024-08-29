import SwiftState

typealias TBStateMachine = StateMachine<TBStateMachineStates, TBStateMachineEvents>

enum TBStateMachineEvents: EventType {
    case startStop, timerFired, skipEvent
}

enum TBStateMachineStates: StateType {
    case idle, work, rest
}
