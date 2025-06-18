TravelGuide 설명서


1.1 프로젝트 정의
	•	한국관광공사 TourAPI, ARKit, Core ML, FirebaseAuth/Firestore, Kingfisher 등
	•	여행지 목록·필터·검색 → 즐겨찾기 → 개인화 추천 → AR 컴퍼스 → 계정·설정 기능을 제공하는 iOS 앱


1.2 프로젝트 배경
	•	수천 개의 관광지 정보를 손쉽게 탐색할 수 있는 모바일 가이드 필요
	•	지도상이 아닌 눈앞에 보이는 길찾기 기능 필요

1.3 프로젝트 목표
	•	여행지 검색·필터: 지역·카테고리·키워드로 즉시 필터링
	•	즐겨찾기: 터치·스와이프로 추가/제거, Firebase 동기화
	•	개인화 추천: 협업 필터링(CF), 콘텐츠 기반(KNN), 위치 보정(Geo) 하이브리드
	•	AR 컴퍼스: ARKit으로 주변 POI 방향·거리 시각화
	•	계정 관리: 익명·Apple 로그인, 로그아웃, 사용자 프로필
	•	설정: 푸시 토글, 캐시 삭제, 앱 버전 표시

2. 프로젝트 개요

2.1 프로젝트 설명
	1.	여행지 목록 화면
	•	ActionSheet로 지역(전국 17개 시·도)·카테고리(관광지·문화·축제·코스·레포츠·숙박·쇼핑·음식점) 선택
	•	검색바로 실시간 키워드 검색
	2.	즐겨찾기 화면
	•	SwiftUI List, 스와이프 및 별 아이콘 토글
	•	Firestore 실시간 동기화 + 로컬 캐시
	3.	추천 화면
	•	현 위치 기준 하이브리드 ML 추천
	•	위치 권한 요청 및 거리 기반 fallback
	4.	AR 컴퍼스 화면
	•	ARSCNView로 POI 마커 표시
	•	CoreLocation과 SceneKit 사용
	5.	More 탭 (내 정보·설정)
	•	익명 ↔ Apple 로그인, 로그아웃
	•	푸시 알림 토글, 캐시 삭제, 앱 버전
 2.2 프로젝트 구조
 	![image](https://github.com/user-attachments/assets/cc459b47-2f2b-4afe-a794-0c32229556c9)

 2.3 결과물 (스크린샷)
	1.	메인 목록 화면
 ![Simulator Screenshot - iPhone 16 Pro - 2025-06-17 at 09 57 09](https://github.com/user-attachments/assets/4dcbe3a4-3fb4-4b45-9e6d-025fdf9781f1)
	2.	즐겨찾기 화면
![Simulator Screenshot - iPhone 16 Pro - 2025-06-17 at 09 58 29](https://github.com/user-attachments/assets/b832939c-cf8a-412d-a690-4c743b5165d6)
  3.	추천 화면
![Simulator Screenshot - iPhone 16 Pro - 2025-06-17 at 09 59 11](https://github.com/user-attachments/assets/38318196-df2f-4f51-8556-2e2b9076f846)
	4.	AR 컴퍼스
 
 	5.	프로필 & 설정
  ![Simulator Screenshot - iPhone 16 Pro - 2025-06-17 at 09 59 53](https://github.com/user-attachments/assets/8143d12a-97b9-44aa-9df0-edb706182cdf)

![Simulator Screenshot - iPhone 16 Pro - 2025-06-17 at 09 59 44](https://github.com/user-attachments/assets/37a16941-ff6c-41d6-810b-5fc506df6c5d)

2.4설명 영상
https://youtube.com/shorts/KXj894moR9Y?feature=share
2.5 관련 기술
구분      기술/라이브러리                        설명
동기화      FirebaseAuth, Firestore           익명/Apple 로그인, 즐겨찾기 실시간 동기화
ML 추천    Core ML (MLRecommender), CBIndex  협업 필터링, 콘텐츠 기반 유사도, 거리 보정
AR        ARKit, SceneKit, CoreLocation     증강현실 컴퍼스, GPS 위치
이미지 처리  Kingfisher                        이미지 비동기 다운로드/캐시

