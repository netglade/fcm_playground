import 'scenario.dart';
import 'scenario_need.dart';

/// **E — Appearance.** How a notification looks once something decides to draw it.
///
/// Split down the middle: `notification.image`, `color` and long or awkward text
/// are FCM fields and work now, while big-picture-from-a-download, large icons and
/// the inbox, messaging and progress styles are all things the *client* builds and
/// FCM has no field for. That division is why half this group is blocked.
const groupE = <Scenario>[
  Scenario(
    id: 'e1_long_text',
    l10nKey: 'e1_long_text',
    group: 'E — Appearance',
    title: 'BigTextStyle with ~800 characters',
    description:
        'Watch where the text is cut in the collapsed view, and whether '
        'expanding shows all of it. Diacritics are included because byte-length '
        'and character-length limits behave differently.',
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
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e2_image_remote',
    l10nKey: 'e2_image_remote',
    group: 'E — Appearance',
    title: 'notification.image — fetched by the platform',
    description:
        'FCM passes a URL and the platform downloads it. Watch that it appears '
        'expanded, and how long it takes on a slow connection.',
    expectation:
        'Android does this natively. iOS requires a Notification Service '
        'Extension, which this app does not ship, so nothing will render there.',
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
    group: 'E — Appearance',
    title: 'Image downloaded by the data handler',
    description:
        'The app fetches the URL itself and builds a BigPictureStyle. Compare '
        'the result and the timing against e2.',
    payloadTemplate: {
      'data': {
        'style': 'big_picture',
        'image_url': 'https://picsum.photos/1200/600',
        'title': 'Downloaded locally',
        'body': 'Built by the app, not the platform.',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e4_image_huge',
    l10nKey: 'e4_image_huge',
    group: 'E — Appearance',
    title: 'A 4000×3000 image',
    description:
        'Watch for a resize, an out-of-memory kill, or a silent failure where '
        'the text arrives and the picture does not.',
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
    group: 'E — Appearance',
    title: 'An image URL that does not resolve',
    description:
        'The important question is whether the text still arrives. A push that '
        'vanishes because its picture 404s is a bad failure mode.',
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
    group: 'E — Appearance',
    title: 'A large icon beside the text',
    description:
        'The round avatar slot, distinct from the small status-bar icon. Watch '
        'that it is circular and not stretched.',
    payloadTemplate: {
      'data': {
        'style': 'large_icon',
        'large_icon_url': 'https://picsum.photos/200/200',
        'title': 'With an avatar',
        'body': 'Round icon on the right.',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e7_inbox_style',
    l10nKey: 'e7_inbox_style',
    group: 'E — Appearance',
    title: 'InboxStyle with seven lines',
    description:
        'Watch how many lines are actually shown when expanded — Android caps '
        'it, and the cap is lower than most people expect.',
    payloadTemplate: {
      'data': {
        'style': 'inbox',
        'title': '7 new builds',
        'lines':
            'build 128 passed|build 127 passed|build 126 failed|build 125 '
            'passed|build 124 passed|build 123 failed|build 122 passed',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e8_messaging_style',
    l10nKey: 'e8_messaging_style',
    group: 'E — Appearance',
    title: 'MessagingStyle with several senders',
    description:
        'The chat layout, with a name and avatar per message. Watch the '
        'grouping and the ordering.',
    payloadTemplate: {
      'data': {
        'style': 'messaging',
        'conversation': 'Release team',
        'messages': 'Ada:ready when you are|Grace:shipping now|Ada:👍',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e9_progress',
    l10nKey: 'e9_progress',
    group: 'E — Appearance',
    title: 'A progress bar, updated in place',
    description:
        'Several pushes updating one notification. Watch that it updates rather '
        'than stacking, and what happens when it completes.',
    payloadTemplate: {
      'data': {
        'style': 'progress',
        'title': 'Downloading',
        'progress': '40',
        'max': '100',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e10_color_and_icon',
    l10nKey: 'e10_color_and_icon',
    group: 'E — Appearance',
    title: 'Accent colour and a monochrome icon',
    description:
        'The classic Xiaomi white-square bug: a small icon that is not a flat '
        'monochrome alpha mask renders as a filled block. Watch the status bar.',
    expectation:
        'The icon must be a monochrome drawable with transparency. A full-colour '
        'launcher icon is what produces the white square.',
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
    group: 'E — Appearance',
    title: 'Emoji, right-to-left text and unbreakable words',
    description:
        'Watch the text direction of the Arabic line, whether the emoji render '
        'in colour, and where a word with no spaces is broken.',
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
