import 'package:fcm_gallery_shared/src/scenarios/scenario.dart';
import 'package:fcm_gallery_shared/src/scenarios/scenario_need.dart';

/// **E — Appearance.** How a notification looks once something decides to draw it.
///
/// Split down the middle, though both halves work now: `notification.image`,
/// `color` and long or awkward text are FCM fields, while
/// big-picture-from-a-download, large icons and the inbox, messaging and
/// progress styles are things FCM has no field for at all — the client reads
/// them off `data.style` and builds them itself. See
/// `notification_appearance.dart`.
const groupE = <Scenario>[
  Scenario(
    id: 'e1_long_text',
    l10nKey: 'e1_long_text',
    group: 'E',
    payloadTemplate: {
      'notification': {
        'title': 'Release notes',
        'body':
            'Tato zpráva je záměrně velmi dlouhá, protože potřebujeme zjistit, '
            'kde přesně Android text ořízne ve sbalené podobě a co se stane po '
            'rozbalení. Obsahuje diakritiku — ěščřžýáíé — aby bylo vidět, jestli '
            'se limit počítá v bajtech nebo ve znacích, což se u UTF-8 liší '
            'zásadně. Dále obsahuje několik vět za sebou, aby bylo možné '
            'posoudit, jak se zachází s odstavci a zda se zachovají mezery mezi '
            'větami. Notifikace tohoto typu se v praxi používají pro poznámky k '
            'vydání, delší zprávy v chatu nebo popisy chyb, takže je užitečné '
            'vědět, kolik textu má vůbec smysl posílat a kdy je lepší otevřít '
            'aplikaci. Pokud se text ořízne příliš brzy, je nutné zvolit jiný '
            'styl notifikace nebo zkrátit obsah na serveru ještě před odesláním.',
      },
    },
  ),
  Scenario(
    id: 'e2_image_remote',
    l10nKey: 'e2_image_remote',
    group: 'E',
    payloadTemplate: {
      'notification': {
        'title': 'With an image',
        'body': 'Expand to see it.',
        'image': 'https://picsum.photos/1200/600',
      },
    },
  ),
  Scenario(
    id: 'e3_image_local',
    l10nKey: 'e3_image_local',
    group: 'E',
    payloadTemplate: {
      'data': {
        'style': 'big_picture',
        'image_url': 'https://picsum.photos/1200/600',
        'title': 'Downloaded locally',
        'body': 'Built by the app, not the platform.',
      },
    },
  ),
  Scenario(
    id: 'e4_image_huge',
    l10nKey: 'e4_image_huge',
    group: 'E',
    payloadTemplate: {
      'notification': {
        'title': 'Very large image',
        'body': 'Does this survive?',
        'image': 'https://picsum.photos/4000/3000',
      },
    },
  ),
  Scenario(
    id: 'e5_image_404',
    l10nKey: 'e5_image_404',
    group: 'E',
    payloadTemplate: {
      'notification': {
        'title': 'Broken image',
        'body': 'The text should still be here.',
        'image': 'https://example.test/missing.png',
      },
    },
  ),
  Scenario(
    id: 'e6_large_icon',
    l10nKey: 'e6_large_icon',
    group: 'E',
    payloadTemplate: {
      'data': {
        'style': 'large_icon',
        'large_icon_url': 'https://picsum.photos/200/200',
        'title': 'With an avatar',
        'body': 'Round icon on the right.',
      },
    },
  ),
  Scenario(
    id: 'e7_inbox_style',
    l10nKey: 'e7_inbox_style',
    group: 'E',
    payloadTemplate: {
      'data': {
        'style': 'inbox',
        'title': '7 new builds',
        'lines':
            'build 128 passed|build 127 passed|build 126 failed|build 125 '
            'passed|build 124 passed|build 123 failed|build 122 passed',
      },
    },
  ),
  Scenario(
    id: 'e8_messaging_style',
    l10nKey: 'e8_messaging_style',
    group: 'E',
    payloadTemplate: {
      'data': {
        'style': 'messaging',
        'conversation': 'Release team',
        'messages': 'Ada:ready when you are|Grace:shipping now|Ada:👍',
      },
    },
  ),
  Scenario(
    id: 'e9_progress',
    l10nKey: 'e9_progress',
    group: 'E',
    payloadTemplate: {
      'data': {
        'style': 'progress',
        'title': 'Downloading',
        'progress': '40',
        'max': '100',
      },
    },
  ),
  Scenario(
    id: 'e10_color_and_icon',
    l10nKey: 'e10_color_and_icon',
    group: 'E',
    payloadTemplate: {
      'notification': {'title': 'Tinted', 'body': 'Check the small icon.'},
      'android': {
        'notification': {'color': '#4285f4', 'icon': 'ic_stat_notify'},
      },
    },
  ),
  Scenario(
    id: 'e11_emoji_rtl',
    l10nKey: 'e11_emoji_rtl',
    group: 'E',
    payloadTemplate: {
      'notification': {
        'title': 'Mixed 🍺 نص عربي',
        'body':
            'مرحبا بالعالم — and a very long unbreakable token: '
            'Donaudampfschiffahrtselektrizitaetenhauptbetriebswerkbauunterbeamten'
            'gesellschaft 🎉🍺🚀',
      },
    },
  ),
];
