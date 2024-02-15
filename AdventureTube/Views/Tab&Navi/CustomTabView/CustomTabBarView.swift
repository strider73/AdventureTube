//
//  CustomTabBarView.swift
//  AdventureTube
//
//  Created by chris Lee on 10/2/22.
//

import SwiftUI

struct CustomTabBarView: View {
    
    let tabs: [TabBarItemInfoEnum]
    // This Binding  came from AdventureTubeTabBar view  which meaning any animation apply  will effect
    // all the way to  origianl  source which is AdventuretubeTabBar in this case
    @Binding var selection :  TabBarItemInfoEnum
    @Namespace private var namespace
    @State var localSelection : TabBarItemInfoEnum

    
    var body: some View {
        HStack {
            ForEach(tabs) { tab in
                tabView1(tab: tab)
                    .onTapGesture {
                        switchToTab(tab: tab)
                    }
            }
        }
        .padding(6)
        .background(Color.white.ignoresSafeArea( edges: .bottom))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .onChange(of: selection ,perform : { tab in
                withAnimation(.easeInOut) {
                    localSelection = tab
                }
            })
    }
    
    private func switchToTab(tab: TabBarItemInfoEnum){
            selection = tab
    }
    
}

struct CustomTabBarView_Previews: PreviewProvider {
    
    static let tabs : [TabBarItemInfoEnum] = [
        .storymap, .mystory, .savedstory , .setting
    ]
    
    static var previews: some View {
        VStack {
            Spacer()
                .background(Color.green)
            CustomTabBarView(tabs: tabs, selection:.constant(tabs.first!),localSelection: tabs.first!)
                .background(Color.yellow)
        }
        .background(Color.purple)
    }
}
extension CustomTabBarView {

    
    private func tabView1(tab: TabBarItemInfoEnum) -> some View {
        VStack {
            Image(systemName: tab.iconName)
                .font(.subheadline)
            Text(tab.title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundColor(localSelection == tab ? tab.color : Color.gray)
        .padding(.vertical,8)
        .frame(maxWidth:.infinity)
        .background(
            ZStack{
                if localSelection == tab {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tab.color.opacity(0.2))
                        .matchedGeometryEffect(id: "background_rectangle", in: namespace)
                }
            }
        )
    }
    

    private func tabView2 (tab: TabBarItemInfoEnum) -> some View {
        VStack {
            Image(systemName: tab.iconName)
                .font(.subheadline)
            Text(tab.title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundColor(selection == tab ? tab.color : Color.gray)
        .padding(.vertical,8)
        .frame(maxWidth:.infinity)
        .background(
            ZStack{
                if localSelection == tab{
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tab.color.opacity(0.2))
                        .matchedGeometryEffect(id: "background_rectangle", in: namespace)
                }
            }
        )
    }

    private func tabView4(tab: TabBarItemInfoEnum) -> some View {
        VStack {
            Image(systemName: tab.iconName)
                .font(.subheadline)
            Text(tab.title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundColor(localSelection == tab ? tab.color : Color.gray)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if localSelection == tab {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tab.color.opacity(0.2))
                        .matchedGeometryEffect(id: "background_rectangle", in: namespace)
                }
            }
        )
    }


}


