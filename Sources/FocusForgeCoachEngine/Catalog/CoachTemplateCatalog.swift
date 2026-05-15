import Foundation

/// The bundled template catalog — the data layer of the coach.
///
/// Three classes of templates live here:
/// - ``framingTemplates`` — shown before a focus session starts.
/// - ``reflectionTemplates`` — shown after a session completes.
/// - ``nudgeTemplates`` — shown when a streak is at risk.
///
/// Every string of user-facing copy in the entire coach lives in this file.
/// No model weights, no remote fetches, no inference — just hand-authored
/// templates routed by simple condition matching. That property is what makes
/// the coach inspectable and the privacy claim ("your work data never leaves
/// your phone") provable.
///
/// To customize the coach without forking, copy `framingTemplates`,
/// `reflectionTemplates`, or `nudgeTemplates` into your own array and pass it
/// to ``CoachTemplateEngine`` via the catalog-injection initializers. The
/// default static APIs use this bundled catalog.
public enum CoachTemplateCatalog {

    // MARK: Keyword → Category Mapping

    /// Maps lowercased task-name words to a category bucket. The engine reads
    /// this when picking a framing template — e.g. a task containing "essay"
    /// routes to the "writing" category.
    ///
    /// Unmapped words fall through to the "general" category, so this map can
    /// stay narrow without breaking anything.
    public static let keywordCategories: [String: String] = [
        "study": "study", "exam": "study", "review": "study", "lecture": "study",
        "class": "study", "homework": "study", "quiz": "study", "read": "study",
        "write": "writing", "essay": "writing", "report": "writing", "blog": "writing",
        "document": "writing", "draft": "writing", "paper": "writing",
        "code": "coding", "program": "coding", "debug": "coding", "develop": "coding",
        "build": "coding", "bug": "coding", "test": "coding", "deploy": "coding",
        "design": "creative", "draw": "creative", "create": "creative",
        "brainstorm": "creative", "sketch": "creative", "paint": "creative",
        "clean": "chores", "organize": "chores", "sort": "chores", "tidy": "chores",
        "laundry": "chores", "dishes": "chores", "declutter": "chores",
    ]

    // MARK: - Framing Templates

    public static let framingTemplates: [FramingTemplate] = [
        FramingTemplate(
            id: "frm_gen_01", category: "general", condition: .default,
            reframeFormat: [
                .encouraging: "Let's focus on: %@. Pick one specific outcome to aim for.",
                .direct: "Target: %@. Define one deliverable before you start.",
                .calm: "For this session, gently focus on: %@. What one small thing can you finish?",
            ],
            motivationalLine: [
                .encouraging: "You've got this!",
                .direct: "Start strong.",
                .calm: "Take a breath and begin.",
            ]
        ),
        FramingTemplate(
            id: "frm_gen_02", category: "general", condition: .lowCompletion,
            reframeFormat: [
                .encouraging: "Let's keep it simple: %@. What's the smallest step you can finish?",
                .direct: "Small win: %@. Pick the easiest piece to knock out first.",
                .calm: "Take it easy with %@. Just one small, completable step.",
            ],
            motivationalLine: [
                .encouraging: "Small wins build big momentum!",
                .direct: "One step at a time.",
                .calm: "Progress over perfection.",
            ]
        ),
        FramingTemplate(
            id: "frm_gen_03", category: "general", condition: .highAbandon,
            reframeFormat: [
                .encouraging: "Just the first step of %@. Nothing more, nothing less.",
                .direct: "One thing only: start %@ and finish the first chunk.",
                .calm: "Begin %@ gently. If you finish the first step, that's enough.",
            ],
            motivationalLine: [
                .encouraging: "Starting is the hardest part — you're already here!",
                .direct: "Commit to just the beginning.",
                .calm: "Be kind to yourself. Just start.",
            ]
        ),
        FramingTemplate(
            id: "frm_gen_04", category: "general", condition: .newUser,
            reframeFormat: [
                .encouraging: "Great choice to focus on %@! What's the first thing you'll tackle?",
                .direct: "%@: decide your first action before the timer starts.",
                .calm: "Welcome to your focus session on %@. Choose one thing to start with.",
            ],
            motivationalLine: [
                .encouraging: "Welcome! Every session is a step forward.",
                .direct: "Let's build a habit.",
                .calm: "This is your time. Make it count.",
            ]
        ),
        FramingTemplate(
            id: "frm_study_01", category: "study", condition: .default,
            reframeFormat: [
                .encouraging: "Study session: %@. What one concept or section will you master?",
                .direct: "%@: pick one chapter or topic. Lock in.",
                .calm: "Let's explore: %@. Choose a section and settle into it.",
            ],
            motivationalLine: [
                .encouraging: "Your future self will thank you!",
                .direct: "Focus sharpens understanding.",
                .calm: "Learning happens one page at a time.",
            ]
        ),
        FramingTemplate(
            id: "frm_study_02", category: "study", condition: .lowCompletion,
            reframeFormat: [
                .encouraging: "Let's try a lighter study load: %@. Just review one key idea.",
                .direct: "%@: one concept only. Master it before moving on.",
                .calm: "For %@, focus on understanding just one thing deeply.",
            ],
            motivationalLine: [
                .encouraging: "Quality over quantity!",
                .direct: "Depth beats breadth.",
                .calm: "Slow and steady wins.",
            ]
        ),
        FramingTemplate(
            id: "frm_write_01", category: "writing", condition: .default,
            reframeFormat: [
                .encouraging: "Writing session: %@. Aim for one complete section or 500 words.",
                .direct: "%@: one section, start to finish.",
                .calm: "For your writing on %@, choose one small section to complete.",
            ],
            motivationalLine: [
                .encouraging: "Every word counts!",
                .direct: "Write now, edit later.",
                .calm: "Let the words flow naturally.",
            ]
        ),
        FramingTemplate(
            id: "frm_write_02", category: "writing", condition: .highAbandon,
            reframeFormat: [
                .encouraging: "Just get words down for %@. Aim for one paragraph to start.",
                .direct: "%@: write one paragraph. That's it.",
                .calm: "Begin writing about %@. Even a few sentences is a win.",
            ],
            motivationalLine: [
                .encouraging: "A rough draft is better than a blank page!",
                .direct: "Imperfect action beats perfect inaction.",
                .calm: "Permission to write badly granted.",
            ]
        ),
        FramingTemplate(
            id: "frm_code_01", category: "coding", condition: .default,
            reframeFormat: [
                .encouraging: "Coding session: %@. What one function or feature will you complete?",
                .direct: "%@: one function, one test, one commit.",
                .calm: "Let's work on: %@. Pick a single piece to finish.",
            ],
            motivationalLine: [
                .encouraging: "Ship something today!",
                .direct: "Code it, test it, move on.",
                .calm: "One line at a time.",
            ]
        ),
        FramingTemplate(
            id: "frm_code_02", category: "coding", condition: .lowCompletion,
            reframeFormat: [
                .encouraging: "Start small with %@. Can you fix one bug or write one test?",
                .direct: "%@: smallest possible change that works.",
                .calm: "For %@, try tackling just one small piece.",
            ],
            motivationalLine: [
                .encouraging: "Small commits add up!",
                .direct: "Incremental progress.",
                .calm: "Every fix matters.",
            ]
        ),
        FramingTemplate(
            id: "frm_creative_01", category: "creative", condition: .default,
            reframeFormat: [
                .encouraging: "Creative time: %@. Let yourself explore one idea freely.",
                .direct: "%@: pick one concept and develop it.",
                .calm: "This is your space for %@. Follow your curiosity.",
            ],
            motivationalLine: [
                .encouraging: "Let your creativity flow!",
                .direct: "Create something tangible.",
                .calm: "Enjoy the process.",
            ]
        ),
        FramingTemplate(
            id: "frm_chores_01", category: "chores", condition: .default,
            reframeFormat: [
                .encouraging: "Productivity sprint: %@. Pick one area and make it shine!",
                .direct: "%@: one zone, fully done.",
                .calm: "For %@, choose one space and tidy it mindfully.",
            ],
            motivationalLine: [
                .encouraging: "A clean space = a clear mind!",
                .direct: "Get it done.",
                .calm: "Tidying can be meditative.",
            ]
        ),
        FramingTemplate(
            id: "frm_chores_02", category: "chores", condition: .highAbandon,
            reframeFormat: [
                .encouraging: "Quick win: %@. Just 10 things — put away, toss, or organize.",
                .direct: "%@: set a timer, pick up 10 items.",
                .calm: "For %@, start with one small corner. That's plenty.",
            ],
            motivationalLine: [
                .encouraging: "10 items and you're a hero!",
                .direct: "Action over planning.",
                .calm: "A little goes a long way.",
            ]
        ),
        FramingTemplate(
            id: "frm_gen_05", category: "general", condition: .highCompletion,
            reframeFormat: [
                .encouraging: "You're on a roll! For %@, challenge yourself with a stretch goal.",
                .direct: "%@: push yourself. Set a slightly ambitious target.",
                .calm: "Building on your momentum with %@. What feels like a good next step?",
            ],
            motivationalLine: [
                .encouraging: "Your consistency is paying off!",
                .direct: "Keep pushing.",
                .calm: "Trust your rhythm.",
            ]
        ),
    ]

    // MARK: - Reflection Templates

    public static let reflectionTemplates: [ReflectionTemplate] = [
        ReflectionTemplate(
            id: "ref_comp_01", condition: .default, category: .consistency,
            tipText: [
                .encouraging: "Nice work! What helped you stay focused? Try to repeat that tomorrow.",
                .direct: "Session done. Identify what worked and do more of it.",
                .calm: "Well done. Take a moment to notice what helped you focus today.",
            ]
        ),
        ReflectionTemplate(
            id: "ref_comp_02", condition: .highCompletion, category: .momentum,
            tipText: [
                .encouraging: "You're on a roll! Your consistency is building something real.",
                .direct: "Strong streak of completions. Keep the momentum.",
                .calm: "Your steady practice is paying off. Keep going at your own pace.",
            ]
        ),
        ReflectionTemplate(
            id: "ref_comp_03", condition: .lowCompletion, category: .timeManagement,
            tipText: [
                .encouraging: "Every completed session counts! Try a shorter session next time to build momentum.",
                .direct: "Completion rate is low. Consider trying 15 minutes next session.",
                .calm: "It's okay to go shorter. A finished 15-minute session beats an unfinished 25.",
            ]
        ),
        ReflectionTemplate(
            id: "ref_comp_04", condition: .longSession, category: .selfCare,
            tipText: [
                .encouraging: "That was a deep session! Remember to stretch and hydrate before your next one.",
                .direct: "Long session logged. Take a real break before continuing.",
                .calm: "A deep session like that deserves a proper rest. Be gentle with yourself.",
            ]
        ),
        ReflectionTemplate(
            id: "ref_comp_05", condition: .shortSession, category: .momentum,
            tipText: [
                .encouraging: "Quick and effective! Short sessions add up over the day.",
                .direct: "Short session done. Stack a few of these for real progress.",
                .calm: "Even brief focus matters. You showed up, and that counts.",
            ]
        ),
        ReflectionTemplate(
            id: "ref_comp_06", condition: .newUser, category: .consistency,
            tipText: [
                .encouraging: "You finished your session! The hardest part is starting — and you did it.",
                .direct: "First sessions are the foundation. Come back tomorrow.",
                .calm: "A wonderful start. Each session makes the next one easier.",
            ]
        ),
        ReflectionTemplate(
            id: "ref_comp_07", condition: .highAbandon, category: .momentum,
            tipText: [
                .encouraging: "You stuck with it this time! That's a real win worth celebrating.",
                .direct: "Full session completed. That's the standard — keep it up.",
                .calm: "You stayed the course today. That takes real strength.",
            ]
        ),
        ReflectionTemplate(
            id: "ref_comp_08", condition: .default, category: .timeManagement,
            tipText: [
                .encouraging: "Great session! Consider what you'd tackle first if you did another one today.",
                .direct: "Done. Plan your next session target while it's fresh.",
                .calm: "A good session. Let the ideas settle before your next one.",
            ]
        ),
        ReflectionTemplate(
            id: "ref_comp_09", condition: .default, category: .selfCare,
            tipText: [
                .encouraging: "You earned this break! Step away from the screen for a moment.",
                .direct: "Break time. Move your body, rest your eyes.",
                .calm: "Take a moment for yourself. A good break makes the next session better.",
            ]
        ),
        ReflectionTemplate(
            id: "ref_comp_10", condition: .highCompletion, category: .timeManagement,
            tipText: [
                .encouraging: "You're crushing it! Ready to try a slightly longer session next time?",
                .direct: "Consistently finishing. Consider increasing your session length by 5 minutes.",
                .calm: "Your rhythm is strong. When you're ready, a slightly longer session could feel good.",
            ]
        ),
    ]

    // MARK: - Nudge Templates

    public static let nudgeTemplates: [NudgeTemplate] = [
        NudgeTemplate(
            id: "nud_early_01", streakTier: 1...3,
            title: [
                .encouraging: "Keep it going!",
                .direct: "Streak check",
                .calm: "A gentle reminder",
            ],
            body: [
                .encouraging: "Your %d-day streak is just getting started! A quick session keeps it alive.",
                .direct: "Your %d-day streak needs one session today.",
                .calm: "Your young %d-day streak could use a session today. Even a short one counts.",
            ]
        ),
        NudgeTemplate(
            id: "nud_early_02", streakTier: 1...3,
            title: [
                .encouraging: "Don't stop now!",
                .direct: "Session needed",
                .calm: "Your streak awaits",
            ],
            body: [
                .encouraging: "You started something great — %d days and counting. One session today!",
                .direct: "%d-day streak. One session to keep it alive.",
                .calm: "Your %d-day streak is waiting for you. No pressure — even a quick one helps.",
            ]
        ),
        NudgeTemplate(
            id: "nud_mid_01", streakTier: 4...7,
            title: [
                .encouraging: "Almost a full week!",
                .direct: "Streak at risk",
                .calm: "Your streak matters",
            ],
            body: [
                .encouraging: "You've built a %d-day streak! One session today keeps it going strong.",
                .direct: "%d-day streak at risk. Open the app and start a session.",
                .calm: "Your %d-day streak is waiting for you. A brief session is all it takes.",
            ]
        ),
        NudgeTemplate(
            id: "nud_mid_02", streakTier: 4...7,
            title: [
                .encouraging: "You're building a habit!",
                .direct: "Don't break the chain",
                .calm: "Stay on track",
            ],
            body: [
                .encouraging: "%d days of focus! You're building a real habit. Keep it going!",
                .direct: "%d days in. One session keeps the chain going.",
                .calm: "%d days of steady progress. Today can be an easy one.",
            ]
        ),
        NudgeTemplate(
            id: "nud_high_01", streakTier: 8...14,
            title: [
                .encouraging: "Impressive streak!",
                .direct: "Protect your streak",
                .calm: "Your dedication shows",
            ],
            body: [
                .encouraging: "%d days! That's real dedication. One session today keeps the magic alive.",
                .direct: "%d-day streak. You've worked too hard to lose this. Start a session.",
                .calm: "You've been so consistent for %d days. Today can be a light one.",
            ]
        ),
        NudgeTemplate(
            id: "nud_high_02", streakTier: 8...14,
            title: [
                .encouraging: "Double digits!",
                .direct: "Streak reminder",
                .calm: "Keep the flow",
            ],
            body: [
                .encouraging: "%d days and counting! You're in rare territory. Don't let today break the chain.",
                .direct: "%d days. Log one session to maintain it.",
                .calm: "Your %d-day journey is beautiful. A short session today continues it.",
            ]
        ),
        NudgeTemplate(
            id: "nud_long_01", streakTier: 15...999,
            title: [
                .encouraging: "Legendary streak!",
                .direct: "Protect your record",
                .calm: "Your journey continues",
            ],
            body: [
                .encouraging: "A %d-day streak is incredible! Protect it with just one session today.",
                .direct: "%d days. Legendary. One session keeps it alive.",
                .calm: "Your %d-day journey is remarkable. A gentle session today continues it.",
            ]
        ),
        NudgeTemplate(
            id: "nud_long_02", streakTier: 15...999,
            title: [
                .encouraging: "You're an inspiration!",
                .direct: "Streak status: at risk",
                .calm: "A moment for focus",
            ],
            body: [
                .encouraging: "%d days of dedication! You've proven you can do this. One more session!",
                .direct: "%d-day streak at risk. You know what to do.",
                .calm: "After %d days of focus, today deserves a gentle session too.",
            ]
        ),
    ]
}
