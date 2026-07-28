import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/controller/reward_notifier.dart';
import 'package:deep_waste/models/Item.dart';
import 'package:deep_waste/models/reward.dart';
import 'package:deep_waste/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProgressBanner extends StatelessWidget {
  final List<Item> items;

  const ProgressBanner({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final rewardNotifier = Provider.of<RewardNotifier>(context);

    final int totalPoints = items.fold(
      0,
      (sum, item) => sum + (item.count * item.points),
    );

    final Reward? activeReward = rewardNotifier.getActiveReward(totalPoints);

    final double carbonFootPrints = totalPoints * 1.08;

    final double completion = (activeReward?.points ?? 1) == 0
        ? 0
        : totalPoints / (activeReward!.points);

    if (items.isEmpty) {
      return const Center(child: Text("Loading"));
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        top: getProportionateScreenWidth(20),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: getProportionateScreenWidth(15),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF4A3298),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: getProportionateScreenWidth(12),
                    ),
                    children: [
                      TextSpan(
                        text:
                            "Waste managed: ${carbonFootPrints <= 0 ? 0 : getNumber(carbonFootPrints, precision: 2)} Kg Co",
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: activeReward != null
                        ? "$totalPoints / ${activeReward.points} points"
                        : "$totalPoints points",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: getProportionateScreenWidth(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20, right: 10),
                  height: 10,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.all(Radius.circular(10)),
                    child: LinearProgressIndicator(
                      value: completion.clamp(0.0, 1.0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xff69c0dc),
                      ),
                      backgroundColor: const Color(0xffD6D6D6),
                    ),
                  ),
                )
              ],
            ),
          ),
          if (activeReward != null)
            Expanded(
              flex: 1,
              child: Image.asset(
                activeReward.imageURL,
                height: 100,
                width: 350,
              ),
            )
        ],
      ),
    );
  }
}
