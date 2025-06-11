//
//  AppTabController.swift
//  TravelGuide
//
//  Created by 관중 mac on 5/31/25.
//

import UIKit
import SwiftUI

final class AppTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1️⃣ 여행지(목록)
        let listVC = UINavigationController(rootViewController: DestinationListVC())
        listVC.tabBarItem = UITabBarItem(
            title: "여행지",
            image: UIImage(systemName: "map"),
            selectedImage: UIImage(systemName: "map.fill")
        )

        // 2️⃣ 즐겨찾기(SwiftUI)
        let favVC = UIHostingController(rootView: FavoritesListView())
        favVC.tabBarItem = UITabBarItem(
            title: "즐겨찾기",
            image: UIImage(systemName: "star"),
            selectedImage: UIImage(systemName: "star.fill")
        )

        // 3️⃣ 추천
        let recVC = UINavigationController(rootViewController: RecommendationListVC())
        recVC.tabBarItem = UITabBarItem(
            title: "추천",
            image: UIImage(systemName: "sparkles"),
            selectedImage: UIImage(systemName: "sparkles")
        )

        // 4️⃣ AR
        let arVC = UINavigationController(rootViewController: ARCompassViewController())
        arVC.tabBarItem = UITabBarItem(
            title: "AR",
            image: UIImage(systemName: "arkit"),
            selectedImage: UIImage(systemName: "arkit")
        )

        // 5️⃣ 프로필
        let profileVC = UINavigationController(rootViewController: ProfileViewController())
        profileVC.tabBarItem = UITabBarItem(
            title: "내 정보",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        // 6️⃣ 설정  (→ 여섯 번째부터는 iOS가 자동으로 “More” 탭으로 묶음)
        let settingsVC = UINavigationController(rootViewController: SettingsViewController())
        settingsVC.tabBarItem = UITabBarItem(
            title: "설정",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        // ✅ **딱 한 번** 배열 할당
        viewControllers = [listVC, favVC, recVC, arVC, profileVC, settingsVC]
        //               화면에 보이는 순서 ↑
    }
}
