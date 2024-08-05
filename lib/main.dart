import 'package:flutter/material.dart';

import 'src/tinder_card.dart';
import 'src/tinder_card_stack.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final actionHistory = <(CardAction action, ({CardModel card, GlobalKey<TinderCardState> key}) item)>[];
  final availableCards = List.generate(10, (i) {
    return (
      card: CardModel(id: i + 10),
      key: GlobalKey<TinderCardState>(),
    );
  });

  int currentCardIndex = 0;
  ({CardModel card, GlobalKey<TinderCardState> key})? get currentItem => availableCards[currentCardIndex];

  // Stores when the "back animation" should be executed
  int? idCardAnimateBack;
  final canTakeActionNotifier = ValueNotifier(true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tinder Animation')),
      body: Stack(
        children: [
          const Center(child: Text('No more cards here!')),
          Positioned(
            left: 0,
            right: 0,
            bottom: 15,
            child: buildBottomIcons(),
          ),
          RepaintBoundary(
            child: TinderCardStack(
              currentIndex: currentCardIndex,
              children: List.generate(availableCards.length, (i) {
                final current = availableCards[i];

                return TinderCard(
                  key: current.key,
                  startVisible: current.card.id != idCardAnimateBack,
                  padding: const EdgeInsets.only(bottom: 100, top: 25, left: 16, right: 16),
                  cardConstraints: const BoxConstraints(maxWidth: 400),
                  onLeft: () {
                    actionHistory.add((CardAction.remove, current));
                    setState(() => currentCardIndex++);
                  },
                  onRight: () {
                    actionHistory.add((CardAction.save, current));
                    setState(() => currentCardIndex++);
                  },
                  // Do not notify the main scaffold when scroll
                  child: NotificationListener(
                    onNotification: (notification) => true,
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('Card ${current.card.id}', style: Theme.of(context).textTheme.titleLarge),
                      ),
                      const Divider(height: 0),
                      Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            return ListTile(title: Text('Item $index'));
                          },
                        ),
                      ),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> rollBack() async {
    final (action, current) = actionHistory.removeLast();
    canTakeActionNotifier.value = false;
    setState(() {
      currentCardIndex--;
      idCardAnimateBack = current.card.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final executeAction = switch (action) {
        CardAction.remove => current.key.currentState?.animateLeftRollBack,
        CardAction.save => current.key.currentState?.animateRightRollBack,
      };
      executeAction?.call().whenComplete(() => canTakeActionNotifier.value = true);
    });
  }

  Widget buildBottomIcons() {
    return ValueListenableBuilder(
      valueListenable: canTakeActionNotifier,
      builder: (context, canTakeAction, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UnconstrainedBox(
              child: ActionButton(
                mini: true,
                canPress: canTakeAction,
                isEnabled: currentCardIndex < availableCards.length,
                child: const Icon(Icons.delete_outline_outlined),
                onPressed: () {
                  canTakeActionNotifier.value = false;
                  currentItem?.key.currentState?.animateLeft().whenComplete(() {
                    canTakeActionNotifier.value = true;
                  });
                },
              ),
            ),
            const SizedBox(width: 15),
            UnconstrainedBox(
              child: ActionButton(
                canPress: canTakeAction,
                isEnabled: actionHistory.isNotEmpty,
                onPressed: () {
                  canTakeActionNotifier.value = false;
                  rollBack().whenComplete(() => canTakeActionNotifier.value = true);
                },
                child: const Icon(Icons.undo),
              ),
            ),
            const SizedBox(width: 15),
            UnconstrainedBox(
              child: ActionButton(
                mini: true,
                canPress: canTakeAction,
                isEnabled: currentCardIndex < availableCards.length,
                child: const Icon(Icons.bookmark_added),
                onPressed: () {
                  canTakeActionNotifier.value = false;
                  currentItem?.key.currentState?.animateRight().whenComplete(() {
                    canTakeActionNotifier.value = true;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

enum CardAction { remove, save }

class ActionButton extends StatelessWidget {
  final bool isEnabled;
  final bool canPress;
  final Widget child;
  final VoidCallback onPressed;
  final bool mini;
  const ActionButton({
    super.key,
    this.isEnabled = true,
    this.canPress = true,
    this.mini = false,
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: mini,
      disabledElevation: 0,
      elevation: 0,
      foregroundColor: (isEnabled) ? null : Theme.of(context).disabledColor,
      backgroundColor: (isEnabled) //
          ? null
          : Theme.of(context).disabledColor.withOpacity(0.2),
      onPressed: (isEnabled && canPress) ? onPressed : null,
      child: child,
    );
  }
}
