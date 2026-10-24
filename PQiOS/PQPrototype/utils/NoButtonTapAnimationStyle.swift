//
//  NoTapAnimationStyle.swift
//  PQPrototype
//
//  https://stackoverflow.com/questions/61593453/disable-default-button-click-animation-in-swiftui
//

import SwiftUI

struct Stamp: View {
    
    var body: some View{
        GeometryReader(){ proxy in
            ZStack{
                ZStack(alignment: .bottom){
                    RoundedRectangle(cornerRadius: 5, style: .circular)
                        .foregroundColor(.tableWood)
                    Rectangle()
                        .frame(height:5)
                        .foregroundColor(.tableWood)
                    Rectangle()
                        .offset(y:5)
                        .foregroundColor(.black)
                        .frame(width: proxy.size.width * 0.9, height: 5)
                }.frame(height: proxy.size.width/1.75)
                Circle().opacity(0.1)
                    .frame(width: proxy.size.width*0.2+5, height: proxy.size.width*0.2+5)
                    .offset(y: -proxy.size.width*0.2/2)
                RoundedRectangle(cornerRadius: proxy.size.width*0.2/2, style: .circular)
                    .foregroundColor(.tableWood)
                    .shadow(radius: 0)
                    .frame(width: proxy.size.width*0.2, height: proxy.size.width/1.75 )
                    .offset(y:-proxy.size.width/1.75/2)
            }
        }
    }
}

struct ButtonStampAnimationStyle: PrimitiveButtonStyle {
    enum ButtonState {
        case idle, holding, stamping
    }
    
    @State private var currentState: ButtonState = .idle
    @State private var stampCount: Int = 0
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack{
            configuration.label
            // Make the whole button surface tappable. Without this only content in the label is tappable and not whitespace. Order is important so add it before the tap gesture
                .contentShape(Rectangle())
                .onTapGesture(count: 1, perform: {
                    performAction()
                    if currentState == .stamping{
                        configuration.trigger()
                    }
                })
            if currentState != .idle{
                GeometryReader(){ proxy in
                    VStack{
                        Stamp()
                            .frame(width: proxy.size.width, height: proxy.size.height/1.75)
                        // .shadow(radius: currentState == .holding ? 5 : 0, y:currentState == .holding ? 20 : 0)
                        
                            .background(
                                Rectangle()
                                    .fill(Color.red)
                                    .cornerRadius(5)
                                    .shadow(radius: currentState == .holding ? 5 : 0, y:currentState == .holding ? proxy.size.height/2 : 0)
                                    .frame(height: proxy.size.width/1.75)
                            )
                            .onTapGesture(count: 1, perform: {
                                performAction()
                            })
                    }.frame(maxHeight: .infinity, alignment: .top)
                        .offset(x:0, y: -5 + proxy.size.height/2 - proxy.size.width/1.75/2 + (currentState == .holding ? -proxy.size.height/2 : 0))
                        .rotationEffect(.degrees(45))
                }
            }
        }
        .fixedSize(horizontal: true, vertical: true)
    }
    
    private func performAction() {
        if currentState == .idle{
            let curTaps = stampCount
            currentState = .holding
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                //stampCount check ensures this doesnt go off if the stamp was completed and not left hanging
                if curTaps == stampCount && currentState == .holding{
                    currentState = .idle
                }
            }
        }else if currentState == .holding{
            currentState = .stamping
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                currentState = .idle
                stampCount += 1
            }
        }
    }
}

struct StampButtonAnimationStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Make the whole button surface tappable. Without this only content in the label is tappable and not whitespace. Order is important so add it before the tap gesture
            .contentShape(Rectangle())
            .onTapGesture(perform: configuration.trigger)
            .onLongPressGesture(perform: configuration.trigger)
    }
}
