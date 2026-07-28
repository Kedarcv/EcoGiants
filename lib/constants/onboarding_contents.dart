class OnboardingContents {
  final String title;
  final String image;
  final String desc;

  const OnboardingContents({
    required this.title,
    required this.image,
    required this.desc,
  });
}

List<OnboardingContents> contents = [
  OnboardingContents(
    title: "Welcome to Eco-Giants",
    image: "assets/images/onboarding1.png",
    desc: "Join the ZOU sustainability movement. Track, classify, and properly dispose of waste to earn rewards.",
  ),
  OnboardingContents(
    title: "AI Waste Classification",
    image: "assets/images/onboarding2.png",
    desc: "Snap a photo of any waste item and let our AI identify it. Get instant classification with confidence scores.",
  ),
  OnboardingContents(
    title: "QR Verification",
    image: "assets/images/onboarding3.png",
    desc: "Scan QR codes on campus bins to verify proper disposal. Earn points and track your environmental impact.",
  ),
  OnboardingContents(
    title: "Earn & Compete",
    image: "assets/images/coins.png",
    desc: "Climb eco levels, compete on leaderboards, and unlock real ZOU rewards. From Seedling to Eco Giant!",
  ),
];
