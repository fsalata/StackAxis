//
//  ContentView.swift
//  StackAxis
//
//  Created by Fábio Salata on 06/09/20.
//

import SwiftUI

struct ContentView: View {
    let colors: [(Color, CGFloat)] = [(.red, 50), (.green, 30), (.blue, 75)]
    
    @State var horizontal: Bool = true
    
    var body: some View {
        VStack {
            Button("Toggle axis") {
                withAnimation {
                    self.horizontal.toggle()
                }
            }
            
            Stack(elements: colors, axis: horizontal ? .horizontal : .vertical) { item in
                Rectangle()
                    .fill(item.0)
                    .frame(width: item.1, height: item.1)
            }
            .border(Color.black)
        }
    }
}

// Size preference
struct CollectSizePreference: PreferenceKey {
    static let defaultValue: [Int: CGSize] = [:]
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// view modifier
struct CollectSize: ViewModifier {
    var index: Int
    
    func body(content: Content) -> some View {
        content.background(GeometryReader{ proxy in
            Color.clear.preference(key: CollectSizePreference.self,
                                   value: [self.index: proxy.size])
        })
    }
}

// Stack
struct Stack<Element, Content: View>: View {
    var elements: [Element]
    var spacing: CGFloat = 8
    var axis: Axis = .horizontal
    var alignment: Alignment = .topLeading
    var content: (Element) -> Content
    @State private var offsets: [CGPoint] = []
    
    var body: some View {
        ZStack(alignment: alignment) {
            ForEach(elements.indices) { idx in
                self.content(self.elements[idx])
                    .modifier(CollectSize(index: idx))
                    .alignmentGuide(self.alignment.horizontal, computeValue: {
                        self.axis == .horizontal ? -self.offset(at: idx).x :
                            $0[self.alignment.horizontal]
                    })
                    .alignmentGuide(self.alignment.vertical, computeValue: {
                        self.axis == .vertical ? -self.offset(at: idx).y :
                            $0[self.alignment.vertical]
                    })
                
            }
        }
        .onPreferenceChange(CollectSizePreference.self, perform: self.computeOffsets)
    }
    
    private func computeOffsets(sizes: [Int: CGSize]) {
        guard !sizes.isEmpty else { return }
        
        var offsets:[CGPoint] = [.zero]
        
        for idx in 0..<self.elements.count {
            guard let size = sizes[idx] else { fatalError() }
            
            var newPoint = offsets.last!
            newPoint.x += size.width + self.spacing
            newPoint.y += size.height + self.spacing
            offsets.append(newPoint)
        }
        
        self.offsets = offsets
    }
    
    private func offset(at index: Int) -> CGPoint {
        guard index < offsets.endIndex else { return .zero }
        return offsets[index]
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
