import SwiftState

typealias TBStateMachine = StateMachine<TBStateMachineStates, TBStateMachineEvents>

enum TBStateMachineEvents: EventType {
    case startStop, timerFired, waitChoice, skipEvent, sessionCompleted
}

enum TBStateMachineStates: StateType {
    case idle, work, shortRest, longRest
}
