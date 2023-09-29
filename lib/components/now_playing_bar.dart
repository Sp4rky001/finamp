import 'package:audio_service/audio_service.dart';
import 'package:finamp/components/favourite_button.dart';
import 'package:finamp/services/player_screen_theme_provider.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

import '../services/finamp_settings_helper.dart';
import '../services/media_state_stream.dart';
import 'album_image.dart';
import '../models/jellyfin_models.dart';
import '../services/process_artist.dart';
import '../services/music_player_background_task.dart';
import '../screens/player_screen.dart';
import 'PlayerScreen/progress_slider.dart';

class NowPlayingBar extends ConsumerWidget {
  const NowPlayingBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BottomNavBar's default elevation is 8 (https://api.flutter.dev/flutter/material/BottomNavigationBar/elevation.html)
    final imageTheme = ref.watch(playerScreenThemeProvider);

    const elevation = 8.0;
    // final color = Theme.of(context).bottomNavigationBarTheme.backgroundColor;

    final audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();
    final queueService = GetIt.instance<QueueService>();

    return Theme(
      data: ThemeData(
        fontFamily: "LexendDeca",
        colorScheme: imageTheme,
        brightness: Theme.of(context).brightness,
        iconTheme: Theme.of(context).iconTheme.copyWith(
          color: imageTheme?.primary,
        ),
      ),
      child: SimpleGestureDetector(
        onVerticalSwipe: (direction) {
          if (direction == SwipeDirection.up) {
            Navigator.of(context).pushNamed(PlayerScreen.routeName);
          }
        },
        child: StreamBuilder<MediaState>(
          stream: mediaStateStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final playing = snapshot.data!.playbackState.playing;
    
              // If we have a media item and the player hasn't finished, show
              // the now playing bar.
              if (snapshot.data!.mediaItem != null) {
                final item = BaseItemDto.fromJson(
                    snapshot.data!.mediaItem!.extras!["itemJson"]);
    
                return Material(
                  color: IconTheme.of(context).color!.withOpacity(0.1),
                  elevation: elevation,
                  child: SafeArea(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Stack(
                        children: [
                          const ProgressSlider(
                            allowSeeking: false,
                            showBuffer: false,
                            showDuration: false,
                            showPlaceholder: false,
                          ),
                          Dismissible(
                            key: const Key("NowPlayingBar"),
                            direction: FinampSettingsHelper.finampSettings.disableGesture ? DismissDirection.none : DismissDirection.horizontal,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                audioHandler.skipToNext();
                              } else {
                                audioHandler.skipToPrevious();
                              }
                              return false;
                            },
                            background: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1,
                                    child: FittedBox(
                                      fit: BoxFit.fitHeight,
                                      child: Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                        child: Icon(Icons.skip_previous),
                                      ),
                                    ),
                                  ),
                                  AspectRatio(
                                    aspectRatio: 1,
                                    child: FittedBox(
                                      fit: BoxFit.fitHeight,
                                      child: Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                        child: Icon(Icons.skip_next),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: ListTile(
                              onTap: () => Navigator.of(context)
                                  .pushNamed(PlayerScreen.routeName),
                              leading: AlbumImage(item: item),
                              title: Text(
                                snapshot.data!.mediaItem!.title,
                                softWrap: false,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                              ),
                              subtitle: Text(
                                processArtist(
                                    snapshot.data!.mediaItem!.artist, context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    FavoriteButton(
                                      item: item,
                                      onToggle: (isFavorite) {
                                        item.userData!.isFavorite = isFavorite;
                                        snapshot.data!.mediaItem?.extras!["itemJson"] = item.toJson();
                                      },
                                    ),
                                  playing
                                      ? IconButton(
                                          icon: const Icon(Icons.pause),
                                          onPressed: () => audioHandler.pause(),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.play_arrow),
                                          onPressed: () => audioHandler.play(),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return const SizedBox(
                  width: 0,
                  height: 0,
                );
              }
            } else {
              return const SizedBox(
                width: 0,
                height: 0,
              );
            }
          },
        ),
      ),
    );
  }
}
