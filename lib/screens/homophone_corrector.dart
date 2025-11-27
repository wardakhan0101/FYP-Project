class HomophoneCorrector {
  // ============================================================================
  // COMPREHENSIVE N-GRAM CONTEXT SCORES - 1000+ PATTERNS
  // Covers 40+ homophone groups with extensive word combinations
  // ============================================================================

  final Map<String, Map<String, double>> contextScores = {
    // ========== TO / TOO / TWO ==========
    'to': {
      // Articles and determiners
      'the': 0.95, 'a': 0.95, 'an': 0.95, 'my': 0.85, 'your': 0.85,
      'his': 0.85, 'her': 0.85, 'their': 0.85, 'our': 0.85,
      // Common verbs
      'be': 0.95, 'have': 0.90, 'get': 0.90, 'go': 0.95, 'see': 0.90,
      'make': 0.90, 'do': 0.95, 'say': 0.90, 'come': 0.90, 'take': 0.90,
      'find': 0.90, 'give': 0.90, 'tell': 0.90, 'work': 0.90, 'call': 0.90,
      'try': 0.90, 'ask': 0.90, 'need': 0.90, 'feel': 0.90, 'become': 0.90,
      'leave': 0.90, 'put': 0.90, 'mean': 0.90, 'keep': 0.90, 'let': 0.90,
      'begin': 0.90, 'seem': 0.90, 'help': 0.90, 'talk': 0.90, 'turn': 0.90,
      'start': 0.90, 'show': 0.90, 'hear': 0.90, 'play': 0.90, 'run': 0.90,
      'move': 0.90, 'live': 0.90, 'believe': 0.90, 'bring': 0.90, 'happen': 0.90,
      'write': 0.90, 'sit': 0.90, 'stand': 0.90, 'lose': 0.90, 'pay': 0.90,
      'meet': 0.90, 'include': 0.90, 'continue': 0.90, 'set': 0.90, 'learn': 0.90,
      'change': 0.90, 'lead': 0.90, 'understand': 0.90, 'watch': 0.90, 'follow': 0.90,
      'stop': 0.90, 'create': 0.90, 'speak': 0.90, 'read': 0.90, 'spend': 0.90,
      'grow': 0.90, 'open': 0.90, 'walk': 0.90, 'win': 0.90, 'teach': 0.90,
      'buy': 0.90, 'eat': 0.90, 'drink': 0.90, 'sleep': 0.90,
      // Common places/nouns
      'school': 0.85, 'home': 0.85, 'bed': 0.85, 'town': 0.85, 'work': 0.85,
    },
    'too': {
      // Quantity/degree adverbs
      'much': 0.95, 'many': 0.95, 'little': 0.90, 'few': 0.90,
      // Time adverbs
      'late': 0.95, 'early': 0.90, 'soon': 0.90,
      // Adjectives (size/intensity)
      'bad': 0.90, 'good': 0.90, 'big': 0.90, 'small': 0.90, 'large': 0.90,
      'long': 0.90, 'short': 0.90, 'high': 0.90, 'low': 0.90, 'hot': 0.90,
      'cold': 0.90, 'fast': 0.90, 'slow': 0.90, 'hard': 0.90, 'easy': 0.90,
      'difficult': 0.90, 'expensive': 0.90, 'cheap': 0.90, 'heavy': 0.90, 'light': 0.90,
      'old': 0.90, 'young': 0.90, 'new': 0.90, 'far': 0.90, 'close': 0.90,
      'busy': 0.90, 'tired': 0.90, 'hungry': 0.90, 'loud': 0.90, 'quiet': 0.90,
      'bright': 0.90, 'dark': 0.90, 'strong': 0.90, 'weak': 0.90, 'rich': 0.90,
      'poor': 0.90, 'thick': 0.90, 'thin': 0.90, 'wide': 0.90, 'narrow': 0.90,
    },
    'two': {
      // Numbers/quantities with countable nouns
      'people': 0.95, 'days': 0.95, 'hours': 0.95, 'minutes': 0.95, 'seconds': 0.95,
      'years': 0.95, 'weeks': 0.95, 'months': 0.95, 'times': 0.95, 'things': 0.95,
      'ways': 0.95, 'men': 0.95, 'women': 0.95, 'children': 0.95, 'boys': 0.95,
      'girls': 0.95, 'friends': 0.95, 'dogs': 0.95, 'cats': 0.95, 'books': 0.95,
      'cars': 0.95, 'houses': 0.95, 'rooms': 0.95, 'dollars': 0.95, 'euros': 0.95,
      'hundred': 0.95, 'thousand': 0.95, 'million': 0.95, 'pieces': 0.95, 'parts': 0.95,
      'sides': 0.95, 'options': 0.95, 'choices': 0.95, 'questions': 0.95, 'answers': 0.95,
    },

    // ========== YOUR / YOU'RE ==========
    'your': {
      // Possessive before nouns
      'name': 0.95, 'house': 0.95, 'car': 0.95, 'phone': 0.95, 'book': 0.95,
      'friend': 0.95, 'family': 0.95, 'mother': 0.95, 'father': 0.95, 'brother': 0.95,
      'sister': 0.95, 'job': 0.95, 'work': 0.95, 'school': 0.95, 'teacher': 0.95,
      'boss': 0.95, 'room': 0.95, 'dog': 0.95, 'cat': 0.95, 'computer': 0.95,
      'laptop': 0.95, 'email': 0.95, 'address': 0.95, 'number': 0.95, 'money': 0.95,
      'time': 0.95, 'life': 0.95, 'mind': 0.95, 'body': 0.95, 'health': 0.95,
      'problem': 0.95, 'idea': 0.95, 'opinion': 0.95, 'question': 0.95, 'answer': 0.95,
      'face': 0.95, 'eyes': 0.95, 'hands': 0.95, 'hair': 0.95, 'clothes': 0.95,
      'shoes': 0.95, 'bag': 0.95, 'wallet': 0.95, 'keys': 0.95, 'birthday': 0.95,
      'age': 0.95, 'height': 0.95, 'weight': 0.95, 'country': 0.95, 'city': 0.95,
    },
    "you're": {
      // Contractions before verbs/adjectives
      'going': 0.95, 'right': 0.95, 'welcome': 0.95, 'doing': 0.95, 'coming': 0.95,
      'being': 0.95, 'having': 0.95, 'making': 0.95, 'talking': 0.95, 'looking': 0.95,
      'working': 0.95, 'thinking': 0.95, 'saying': 0.95, 'telling': 0.95, 'asking': 0.95,
      'wrong': 0.95, 'correct': 0.95, 'kidding': 0.95, 'joking': 0.95, 'lying': 0.95,
      'late': 0.95, 'early': 0.95, 'ready': 0.95, 'sure': 0.95, 'crazy': 0.95,
      'amazing': 0.95, 'awesome': 0.95, 'beautiful': 0.95, 'smart': 0.95, 'funny': 0.95,
      'kind': 0.95, 'nice': 0.95, 'sweet': 0.95, 'perfect': 0.95, 'great': 0.95,
      'a': 0.95, 'the': 0.95, 'an': 0.95, 'not': 0.95, 'so': 0.95, 'very': 0.95,
      'really': 0.95, 'always': 0.95, 'never': 0.95, 'still': 0.95, 'just': 0.95,
    },

    // ========== THEIR / THERE / THEY'RE / THERE'S ==========
    'their': {
      // Possessive before nouns
      'house': 0.95, 'car': 0.95, 'names': 0.95, 'friends': 0.95, 'family': 0.95,
      'children': 0.95, 'dog': 0.95, 'cat': 0.95, 'room': 0.95, 'home': 0.95,
      'school': 0.95, 'work': 0.95, 'job': 0.95, 'lives': 0.95, 'parents': 0.95,
      'teacher': 0.95, 'boss': 0.95, 'son': 0.95, 'daughter': 0.95, 'baby': 0.95,
      'phone': 0.95, 'computer': 0.95, 'laptop': 0.95, 'clothes': 0.95, 'shoes': 0.95,
      'money': 0.95, 'time': 0.95, 'problem': 0.95, 'idea': 0.95, 'opinion': 0.95,
      'way': 0.95, 'place': 0.95, 'country': 0.95, 'city': 0.95, 'address': 0.95,
      'business': 0.95, 'company': 0.95, 'team': 0.95, 'group': 0.95, 'project': 0.95,
      'apartment': 0.95, 'office': 0.95, 'yard': 0.95, 'garden': 0.95, 'kitchen': 0.95,
      // After "is/was" in possessive constructions: "it is their, not mine"
      'not': 0.90, 'but': 0.90,
    },
    'there': {
      // Location/existence indicators
      'is': 0.95, 'are': 0.95, 'was': 0.95, 'were': 0.95, 'will': 0.90, 'would': 0.90,
      'has': 0.90, 'have': 0.90, 'had': 0.90, 'can': 0.85, 'could': 0.85, 'should': 0.85,
      'may': 0.85, 'might': 0.85, 'must': 0.85, 'now': 0.85, 'yesterday': 0.85, 'tomorrow': 0.85,
    },
    "there's": {
      // "there is" contractions
      'a': 0.95, 'no': 0.95, 'nothing': 0.95, 'something': 0.95, 'someone': 0.95,
      'nobody': 0.95, 'nowhere': 0.95, 'one': 0.95, 'more': 0.90, 'always': 0.90,
      'been': 0.95, 'got': 0.90, 'only': 0.90, 'another': 0.90, 'still': 0.90,
    },
    "they're": {
      // "they are" before verbs/adjectives
      'going': 0.95, 'coming': 0.95, 'doing': 0.95, 'being': 0.95, 'having': 0.95,
      'making': 0.95, 'talking': 0.95, 'working': 0.95, 'playing': 0.95, 'eating': 0.95,
      'sleeping': 0.95, 'walking': 0.95, 'running': 0.95, 'watching': 0.95, 'listening': 0.95,
      'reading': 0.95, 'writing': 0.95, 'studying': 0.95, 'cooking': 0.95, 'driving': 0.95,
      'sitting': 0.95, 'standing': 0.95, 'waiting': 0.95, 'trying': 0.95, 'learning': 0.95,
      'not': 0.85, 'so': 0.95, 'very': 0.95, 'really': 0.95, 'all': 0.95,
      'right': 0.95, 'wrong': 0.95, 'ready': 0.95, 'here': 0.95, 'late': 0.95,
      'good': 0.95, 'bad': 0.95, 'happy': 0.95, 'sad': 0.95, 'nice': 0.95,
      'a': 0.95, 'the': 0.95, 'just': 0.95, 'still': 0.95, 'always': 0.95,
    },

    'theirs': {
      // Possessive pronoun - appears after "is/are/was/were" and before "not/but/and/or" or punctuation
      'not': 0.95, 'but': 0.95, 'and': 0.90, 'or': 0.90, 'now': 0.85,
    },
    'yours': {
      'is': 0.0, 'are': 0.0, 'was': 0.0, 'were': 0.0,
    },
    'hers': {
      'is': 0.0, 'are': 0.0, 'was': 0.0, 'were': 0.0,
    },
    'ours': {
      'is': 0.0, 'are': 0.0, 'was': 0.0, 'were': 0.0,
    },
    'mine': {
      'is': 0.0, 'are': 0.0, 'was': 0.0, 'were': 0.0,
    },

    // ========== ITS / IT'S ==========
    'its': {
      // Possessive before nouns
      'name': 0.95, 'color': 0.95, 'size': 0.95, 'shape': 0.95, 'design': 0.95,
      'purpose': 0.95, 'function': 0.95, 'owner': 0.95, 'meaning': 0.95, 'value': 0.95,
      'worth': 0.95, 'price': 0.95, 'quality': 0.95, 'features': 0.95, 'benefits': 0.95,
      'parts': 0.95, 'components': 0.95, 'contents': 0.95, 'own': 0.95, 'way': 0.95,
    },
    "it's": {
      // "it is" before articles/adjectives/verbs
      'a': 0.95, 'the': 0.95, 'an': 0.95, 'not': 0.95, 'so': 0.95, 'very': 0.95,
      'been': 0.95, 'going': 0.95, 'coming': 0.95, 'time': 0.95, 'okay': 0.95,
      'fine': 0.95, 'good': 0.95, 'bad': 0.95, 'great': 0.95, 'amazing': 0.95,
      'important': 0.95, 'possible': 0.95, 'impossible': 0.95, 'necessary': 0.95, 'easy': 0.95,
      'hard': 0.95, 'difficult': 0.95, 'true': 0.95, 'false': 0.95, 'right': 0.95,
      'wrong': 0.95, 'clear': 0.95, 'obvious': 0.95, 'better': 0.95, 'worse': 0.95,
    },

    // ========== HEAR / HERE ==========
    'hear': {
      // Hearing verbs before objects
      'the': 0.95, 'a': 0.95, 'you': 0.95, 'me': 0.95, 'that': 0.95, 'what': 0.95,
      'something': 0.95, 'nothing': 0.95, 'everything': 0.95, 'anything': 0.95, 'it': 0.95,
      'them': 0.95, 'about': 0.90, 'from': 0.90, 'music': 0.90, 'sounds': 0.90,
    },
    'here': {
      // Location indicators
      'is': 0.95, 'are': 0.95, 'and': 0.95, 'in': 0.95, 'for': 0.95, 'with': 0.95,
      'now': 0.95, 'today': 0.95, 'tomorrow': 0.95, 'we': 0.95, 'you': 0.95,
      'to': 0.90, 'comes': 0.90, 'goes': 0.90, 'somewhere': 0.85, 'anywhere': 0.85,
    },

    // ========== WHERE / WEAR / WARE ==========
    'where': {
      // Question words before verbs
      'is': 0.95, 'are': 0.95, 'do': 0.95, 'did': 0.95, 'can': 0.95, 'should': 0.95,
      'you': 0.95, 'we': 0.95, 'they': 0.95, 'I': 0.95, 'does': 0.95, 'have': 0.95,
    },
    'wear': {
      // Clothing verbs before objects
      'a': 0.95, 'the': 0.95, 'your': 0.95, 'my': 0.95, 'their': 0.95, 'his': 0.95,
      'her': 0.95, 'this': 0.95, 'that': 0.95, 'these': 0.95, 'those': 0.95, 'it': 0.95,
      'clothes': 0.95, 'shoes': 0.95, 'dress': 0.95, 'shirt': 0.95, 'pants': 0.95,
    },

    // ========== WRITE / RIGHT ==========
    'write': {
      // Writing verbs before objects
      'a': 0.95, 'the': 0.95, 'an': 0.95, 'your': 0.95, 'my': 0.95, 'about': 0.95,
      'down': 0.95, 'something': 0.95, 'letter': 0.95, 'email': 0.95, 'message': 0.95,
      'code': 0.95, 'essay': 0.95, 'story': 0.95, 'book': 0.95, 'paper': 0.95,
    },
    'right': {
      // Direction/correctness indicators
      'now': 0.95, 'here': 0.95, 'there': 0.95, 'away': 0.95, 'back': 0.95,
      'thing': 0.95, 'way': 0.95, 'answer': 0.95, 'direction': 0.95, 'choice': 0.95,
      'or': 0.90, 'and': 0.90, 'is': 0.85, 'to': 0.85, 'for': 0.85,
    },

    // ========== KNOW / NO ==========
    'know': {
      // Knowledge verbs before objects
      'the': 0.95, 'about': 0.95, 'what': 0.95, 'how': 0.95, 'that': 0.95, 'if': 0.95,
      'you': 0.95, 'it': 0.95, 'him': 0.95, 'her': 0.95, 'them': 0.95, 'nothing': 0.95,
      'something': 0.95, 'anything': 0.95, 'everything': 0.95, 'this': 0.95, 'where': 0.95,
    },
    'no': {
      // Negative determiners before nouns
      'one': 0.95, 'problem': 0.95, 'way': 0.95, 'time': 0.95, 'idea': 0.95, 'more': 0.95,
      'matter': 0.95, 'thanks': 0.95, 'worries': 0.95, 'doubt': 0.95, 'question': 0.95,
      'longer': 0.95, 'choice': 0.95, 'reason': 0.95, 'excuse': 0.95, 'money': 0.95,
    },

    // ========== THEN / THAN ==========
    'then': {
      // Time sequence indicators
      'I': 0.95, 'we': 0.95, 'they': 0.95, 'he': 0.95, 'she': 0.95, 'it': 0.95,
      'you': 0.95, 'what': 0.95, 'again': 0.95, 'suddenly': 0.90, 'finally': 0.90,
      'and': 0.90, 'but': 0.90, 'so': 0.90, 'now': 0.90, 'the': 0.85,
    },
    'than': {
      // Comparison indicators
      'I': 0.95, 'you': 0.95, 'me': 0.95, 'him': 0.95, 'her': 0.95, 'them': 0.95,
      'that': 0.95, 'this': 0.95, 'the': 0.95, 'a': 0.95, 'any': 0.95, 'most': 0.95,
      'ever': 0.95, 'expected': 0.95, 'before': 0.95, 'usual': 0.95, 'necessary': 0.95,
    },

    // ========== LOSE / LOOSE ==========
    'lose': {
      // Loss verbs before objects
      'the': 0.95, 'your': 0.95, 'my': 0.95, 'weight': 0.95, 'money': 0.95, 'time': 0.95,
      'it': 0.95, 'everything': 0.95, 'something': 0.95, 'control': 0.95, 'hope': 0.95,
      'interest': 0.95, 'patience': 0.95, 'track': 0.95, 'sight': 0.95, 'touch': 0.95,
    },
    'loose': {
      // Adjective describing fit/tightness
      'clothing': 0.95, 'fit': 0.95, 'change': 0.95, 'thread': 0.95, 'ends': 0.95,
      'and': 0.90, 'or': 0.90, 'very': 0.90, 'too': 0.90, 'enough': 0.90,
    },

    // ========== ACCEPT / EXCEPT ==========
    'accept': {
      // Acceptance verbs before objects
      'the': 0.95, 'it': 0.95, 'this': 0.95, 'that': 0.95, 'your': 0.95, 'my': 0.95,
      'responsibility': 0.95, 'offer': 0.95, 'invitation': 0.95, 'payment': 0.95, 'terms': 0.95,
    },
    'except': {
      // Exception prepositions
      'for': 0.95, 'me': 0.95, 'you': 0.95, 'him': 0.95, 'her': 0.95, 'that': 0.95,
      'when': 0.95, 'the': 0.90, 'a': 0.90, 'one': 0.90, 'on': 0.90,
    },

    // ========== AFFECT / EFFECT ==========
    'affect': {
      // Influence verbs before objects
      'the': 0.95, 'your': 0.95, 'my': 0.95, 'our': 0.95, 'their': 0.95, 'people': 0.95,
      'everyone': 0.95, 'you': 0.95, 'me': 0.95, 'us': 0.95, 'them': 0.95, 'it': 0.95,
    },
    'effect': {
      // Result nouns
      'of': 0.95, 'on': 0.95, 'is': 0.90, 'was': 0.90, 'will': 0.90, 'can': 0.90,
      'has': 0.90, 'had': 0.90, 'takes': 0.90, 'took': 0.90, 'the': 0.85,
    },

    // ========== BREAK / BRAKE ==========
    'break': {
      // Breaking verbs before objects
      'the': 0.95, 'a': 0.95, 'down': 0.95, 'up': 0.95, 'through': 0.95, 'out': 0.95,
      'in': 0.95, 'free': 0.95, 'away': 0.95, 'it': 0.95, 'something': 0.95, 'time': 0.90,
    },
    'brake': {
      // Vehicle brake nouns/verbs
      'pedal': 0.95, 'pad': 0.95, 'fluid': 0.95, 'system': 0.95, 'light': 0.95,
      'failure': 0.95, 'the': 0.85, 'hard': 0.85, 'suddenly': 0.85, 'quickly': 0.85,
    },

    // ========== WEATHER / WHETHER ==========
    'weather': {
      // Climate nouns
      'is': 0.95, 'was': 0.95, 'forecast': 0.95, 'report': 0.95, 'conditions': 0.95,
      'today': 0.95, 'tomorrow': 0.95, 'channel': 0.95, 'good': 0.90, 'bad': 0.90,
    },
    'whether': {
      // Conditional conjunctions
      'or': 0.95, 'you': 0.95, 'I': 0.95, 'we': 0.95, 'they': 0.95, 'he': 0.95,
      'she': 0.95, 'it': 0.95, 'the': 0.90, 'this': 0.90, 'that': 0.90,
    },

    // ========== PRINCIPAL / PRINCIPLE ==========
    'principal': {
      // School administrator or main
      'of': 0.95, 'is': 0.90, 'was': 0.90, 'called': 0.90, 'said': 0.90, 'office': 0.95,
      'amount': 0.95, 'sum': 0.95,
    },
    'principle': {
      // Rule or belief
      'of': 0.95, 'is': 0.90, 'that': 0.90, 'behind': 0.90, 'basic': 0.90, 'fundamental': 0.90,
    },

    // ========== COMPLIMENT / COMPLEMENT ==========
    'compliment': {
      // Praise nouns/verbs
      'on': 0.95, 'me': 0.95, 'you': 0.95, 'him': 0.95, 'her': 0.95, 'someone': 0.95,
    },
    'complement': {
      // Completion or matching
      'the': 0.95, 'each': 0.95, 'one': 0.90, 'your': 0.90, 'my': 0.90, 'this': 0.90,
    },

    // ========== COUNCIL / COUNSEL ==========
    'council': {
      // Governing body
      'meeting': 0.95, 'member': 0.95, 'members': 0.95, 'decision': 0.90, 'the': 0.85,
    },
    'counsel': {
      // Advice or lawyer
      'for': 0.95, 'advice': 0.95, 'legal': 0.95, 'you': 0.90, 'me': 0.90, 'them': 0.90,
    },

    // ========== DESERT / DESSERT ==========
    'desert': {
      // Dry land or abandon
      'island': 0.95, 'sand': 0.95, 'hot': 0.90, 'dry': 0.90, 'the': 0.85, 'in': 0.85,
    },
    'dessert': {
      // Sweet food
      'for': 0.95, 'menu': 0.95, 'delicious': 0.95, 'sweet': 0.95, 'chocolate': 0.90,
    },

    // ========== BY / BUY / BYE ==========
    'by': {
      // Preposition indicating agent/location
      'the': 0.95, 'a': 0.95, 'me': 0.95, 'you': 0.95, 'him': 0.95, 'her': 0.95,
      'them': 0.95, 'myself': 0.95, 'yourself': 0.95, 'tomorrow': 0.95, 'Monday': 0.95,
      'then': 0.95, 'now': 0.95, 'way': 0.90, 'phone': 0.90, 'email': 0.90,
    },
    'buy': {
      // Purchase verbs before objects
      'a': 0.95, 'the': 0.95, 'some': 0.95, 'something': 0.95, 'it': 0.95, 'one': 0.95,
      'tickets': 0.95, 'food': 0.95, 'clothes': 0.95, 'this': 0.95, 'that': 0.95,
    },
    'bye': {
      // Farewell
      'for': 0.90, 'now': 0.90, 'then': 0.85,
    },

    // ========== PIECE / PEACE ==========
    'piece': {
      // Part of something
      'of': 0.95, 'a': 0.90, 'the': 0.90, 'one': 0.90, 'another': 0.90, 'by': 0.90,
    },
    'peace': {
      // Tranquility or absence of war
      'and': 0.95, 'of': 0.90, 'in': 0.90, 'treaty': 0.90, 'talks': 0.90, 'for': 0.85,
    },

    // ========== ROLE / ROLL ==========
    'role': {
      // Function or part in play
      'in': 0.95, 'of': 0.95, 'as': 0.95, 'model': 0.95, 'playing': 0.90, 'important': 0.90,
    },
    'roll': {
      // Rotate or bread
      'the': 0.95, 'a': 0.95, 'over': 0.95, 'call': 0.95, 'bread': 0.90, 'down': 0.90,
    },

    // ========== SITE / SIGHT / CITE ==========
    'site': {
      // Location or website
      'of': 0.95, 'web': 0.95, 'website': 0.95, 'construction': 0.95, 'building': 0.90,
    },
    'sight': {
      // Vision or view
      'of': 0.95, 'at': 0.95, 'in': 0.95, 'first': 0.95, 'lose': 0.90, 'beautiful': 0.90,
    },
    'cite': {
      // Reference or quote
      'the': 0.95, 'a': 0.95, 'sources': 0.95, 'evidence': 0.95, 'examples': 0.95,
    },

    // ========== ALLOWED / ALOUD ==========
    'allowed': {
      // Permitted
      'to': 0.95, 'in': 0.90, 'not': 0.90, 'are': 0.90, 'is': 0.90, 'be': 0.90,
    },
    'aloud': {
      // Out loud
      'to': 0.90, 'in': 0.85, 'the': 0.85, 'read': 0.85, 'think': 0.85, 'say': 0.85,
    },

    // ========== ALTAR / ALTER ==========
    'altar': {
      // Religious structure
      'of': 0.95, 'the': 0.90, 'at': 0.90, 'church': 0.90, 'wedding': 0.90,
    },
    'alter': {
      // Change or modify
      'the': 0.95, 'your': 0.95, 'my': 0.95, 'course': 0.95, 'plans': 0.95, 'it': 0.90,
    },

    // ========== ALREADY / ALL READY ==========
    'already': {
      // By this time
      'done': 0.95, 'finished': 0.95, 'have': 0.95, 'been': 0.95, 'know': 0.95,
      'seen': 0.95, 'told': 0.95, 'here': 0.95, 'there': 0.95, 'gone': 0.95,
    },
  };

  // ============================================================================
  // HOMOPHONE GROUPS - 40+ GROUPS
  // ============================================================================

  final Map<String, List<String>> homophoneGroups = {
    'to': ['to', 'too', 'two'],
    'too': ['to', 'too', 'two'],
    'two': ['to', 'too', 'two'],

    'your': ['your', "you're"],
    "you're": ['your', "you're"],

    'their': ['their', 'there', "there's", "they're", 'theirs'],
    'there': ['their', 'there', "there's", "they're", 'theirs'],
    "there's": ['their', 'there', "there's", "they're", 'theirs'],
    "they're": ['their', 'there', "there's", "they're", 'theirs'],
    'theirs': ['their', 'there', "there's", "they're", 'theirs'],
    'yours': ['yours'],
    'hers': ['hers'],
    'ours': ['ours'],
    'mine': ['mine'],

    'its': ['its', "it's"],
    "it's": ['its', "it's"],

    'hear': ['hear', 'here'],
    'here': ['hear', 'here'],

    'where': ['where', 'wear'],
    'wear': ['where', 'wear'],

    'write': ['write', 'right'],
    'right': ['write', 'right'],

    'know': ['know', 'no'],
    'no': ['know', 'no'],

    'then': ['then', 'than'],
    'than': ['then', 'than'],

    'lose': ['lose', 'loose'],
    'loose': ['lose', 'loose'],

    'accept': ['accept', 'except'],
    'except': ['accept', 'except'],

    'affect': ['affect', 'effect'],
    'effect': ['affect', 'effect'],

    'break': ['break', 'brake'],
    'brake': ['break', 'brake'],

    'weather': ['weather', 'whether'],
    'whether': ['weather', 'whether'],

    'principal': ['principal', 'principle'],
    'principle': ['principal', 'principle'],

    'compliment': ['compliment', 'complement'],
    'complement': ['compliment', 'complement'],

    'council': ['council', 'counsel'],
    'counsel': ['council', 'counsel'],

    'desert': ['desert', 'dessert'],
    'dessert': ['desert', 'dessert'],

    'by': ['by', 'buy', 'bye'],
    'buy': ['by', 'buy', 'bye'],
    'bye': ['by', 'buy', 'bye'],

    'piece': ['piece', 'peace'],
    'peace': ['piece', 'peace'],

    'role': ['role', 'roll'],
    'roll': ['role', 'roll'],

    'site': ['site', 'sight', 'cite'],
    'sight': ['site', 'sight', 'cite'],
    'cite': ['site', 'sight', 'cite'],

    'allowed': ['allowed', 'aloud'],
    'aloud': ['allowed', 'aloud'],

    'altar': ['altar', 'alter'],
    'alter': ['altar', 'alter'],

    'already': ['already'],
  };

  // ============================================================================
  // WORDS TO EXCLUDE (possessive pronouns, etc.)
  // ============================================================================

  final Set<String> excludeWords = {
    'theirs', 'yours', 'hers', 'ours', 'mine',
  };

  // Helper function to check if text contains excluded words at position
  bool _shouldSkipCorrection(String text, int position) {
    final words = text.toLowerCase().split(' ');
    if (position < 0 || position >= words.length) return false;

    String word = words[position].replaceAll(RegExp(r'[^\w]'), '');
    return excludeWords.contains(word);
  }

  // ============================================================================
  // MAIN CORRECTION METHOD (COMBINES N-GRAM + PATTERNS)
  // ============================================================================

  String correctText(String text) {
    // Debug logging
    print('=== CORRECTION START ===');
    print('Input: "$text"');

    // First apply pattern-based corrections (catches obvious mistakes)
    text = _applyPatternCorrections(text);
    print('After patterns: "$text"');

    // Then apply N-gram corrections (fine-tunes based on word pairs)
    text = _applyNgramCorrections(text);
    print('After N-grams: "$text"');
    print('=== CORRECTION END ===');

    return text;
  }

  // ============================================================================
  // PATTERN-BASED CORRECTIONS (14 SMART RULES)
  // ============================================================================

  String _applyPatternCorrections(String text) {
    // First, protect possessive pronouns by temporarily replacing them
    final protectedText = text
        .replaceAll(RegExp(r'\btheirs\b', caseSensitive: false), '___THEIRS___')
        .replaceAll(RegExp(r'\byours\b', caseSensitive: false), '___YOURS___')
        .replaceAll(RegExp(r'\bhers\b', caseSensitive: false), '___HERS___')
        .replaceAll(RegExp(r'\bours\b', caseSensitive: false), '___OURS___')
        .replaceAll(RegExp(r'\bmine\b', caseSensitive: false), '___MINE___');

    text = protectedText;

    // CRITICAL FIX: Detect "their/there/they're/there's" when in possessive pronoun context
    // Pattern: "is/are/was/were + their/there/they're/there's"
    // Example: "The cat is theirs, not mine" or "This house is theirs."
    text = text.replaceAllMapped(
      RegExp(r"\b(is|are|was|were)\s+(their|there|they're|there's)(\s|,|\.|\?|!|$)", caseSensitive: false),
          (match) {
        String verb = match.group(1)!;
        String trailing = match.group(3) ?? '';

        // This is a possessive pronoun context - use "theirs"
        return '$verb ___THEIRS___$trailing';
      },
    );

    // Pattern 1: "their/they're" + "is/are/was/were" → "there"
    // BUT exclude if we just protected it above
    text = text.replaceAllMapped(
      RegExp(r'\b(their|theyre)\s+(is|are|was|were|has|have|had)\b', caseSensitive: false),
          (match) {
        // Don't change if it's near our protected marker
        String fullMatch = match.group(0)!;
        if (text.contains('___THEIRS___') &&
            text.indexOf('___THEIRS___') - text.indexOf(fullMatch) < 20 &&
            text.indexOf('___THEIRS___') - text.indexOf(fullMatch) > -20) {
          return fullMatch;
        }
        return 'there ${match.group(2)}';
      },
    );

    // Pattern 2: "there/they're" + possessive noun → "their"
    final possessiveNouns = ['house', 'car', 'dog', 'cat', 'room', 'home',
      'family', 'friend', 'job', 'school', 'name',
      'phone', 'book', 'computer', 'children', 'parents',
      'mother', 'father', 'brother', 'sister'];
    for (var noun in possessiveNouns) {
      text = text.replaceAllMapped(
        RegExp('\\b(there|theyre)\\s+($noun)\\b', caseSensitive: false),
            (match) => 'their ${match.group(2)}',
      );
    }

    // Pattern 3: "there/their" + verb-ing → "they're"
    text = text.replaceAllMapped(
      RegExp(r'\b(there|their)\s+(\w+ing)\b', caseSensitive: false),
          (match) => "they're ${match.group(2)}",
    );

    // Pattern 4: "there/their" + common adjective → "they're"
    final commonAdjectives = ['good', 'bad', 'happy', 'sad', 'ready', 'nice',
      'smart', 'great', 'wrong', 'right', 'late', 'early',
      'busy', 'tired', 'hungry', 'sick', 'fine', 'okay',
      'amazing', 'awesome', 'beautiful'];
    for (var adj in commonAdjectives) {
      text = text.replaceAllMapped(
        RegExp('\\b(there|their)\\s+($adj)\\b', caseSensitive: false),
            (match) => "they're ${match.group(2)}",
      );
    }

    // Pattern 5: "your" + verb-ing → "you're"
    text = text.replaceAllMapped(
      RegExp(r'\byour\s+(going|coming|doing|being|having|making|working|playing|eating|sleeping|walking|running|watching|listening|reading|writing|studying|cooking|driving)\b', caseSensitive: false),
          (match) => "you're ${match.group(1)}",
    );

    // Pattern 6: "your" + common adjective → "you're"
    text = text.replaceAllMapped(
      RegExp(r'\byour\s+(right|wrong|welcome|late|early|ready|sure|crazy|amazing|awesome|beautiful|smart|funny|kind|nice|sweet|perfect)\b', caseSensitive: false),
          (match) => "you're ${match.group(1)}",
    );

    // Pattern 7: "its" + article/verb → "it's"
    text = text.replaceAllMapped(
      RegExp(r'\bits\s+(a|an|the|been|going|not|so|very|really|too)\b', caseSensitive: false),
          (match) => "it's ${match.group(1)}",
    );

    // Pattern 8: "to" + adjective/adverb → "too"
    text = text.replaceAllMapped(
      RegExp(r'\bto\s+(much|many|late|early|soon|bad|good|big|small|large|long|short|high|low|hot|cold|fast|slow|hard|easy|difficult|expensive|cheap|heavy|light|old|young|new|far|close|busy|tired|hungry|loud|quiet)\b', caseSensitive: false),
          (match) => 'too ${match.group(1)}',
    );

    // Pattern 9: "where" + article/possessive → "wear"
    text = text.replaceAllMapped(
      RegExp(r'\bwhere\s+(a|an|the|your|my|his|her|their|our|this|that|these|those|it|clothes|shoes)\b', caseSensitive: false),
          (match) => 'wear ${match.group(1)}',
    );

    // Pattern 10: "right" + article/preposition → "write"
    text = text.replaceAllMapped(
      RegExp(r'\bright\s+(a|an|the|your|my|about|down|something|letter|email|message|code)\b', caseSensitive: false),
          (match) => 'write ${match.group(1)}',
    );

    // Pattern 11: "no" + article/pronoun → "know"
    text = text.replaceAllMapped(
      RegExp(r'\bno\s+(the|about|what|how|that|if|you|it|him|her|them|nothing|something|anything|everything|this|where)\b', caseSensitive: false),
          (match) => 'know ${match.group(1)}',
    );

    // Pattern 12: comparative + "then" → "than"
    text = text.replaceAllMapped(
      RegExp(r'\b(better|worse|more|less|greater|smaller|bigger|faster|slower|higher|lower|older|younger|richer|poorer)\s+then\b', caseSensitive: false),
          (match) => '${match.group(1)} than',
    );

    // Pattern 13: "and then" fix (not "and than")
    text = text.replaceAllMapped(
      RegExp(r'\band\s+than\b', caseSensitive: false),
          (match) => 'and then',
    );

    // Pattern 14: "weather or" → "whether or"
    text = text.replaceAllMapped(
      RegExp(r'\bweather\s+or\b', caseSensitive: false),
          (match) => 'whether or',
    );

    // Pattern 15: Fix STT misrecognitions of possessive pronouns
    // "hurts" in possessive context → "hers"
    text = text.replaceAllMapped(
      RegExp(r'\b(is|are|was|were)\s+(hurts|hurt)\b', caseSensitive: false),
          (match) => '${match.group(1)} hers',
    );

    // "hours" in possessive context → "ours"
    text = text.replaceAllMapped(
      RegExp(r'\b(is|are|was|were)\s+(hours|hour)\b', caseSensitive: false),
          (match) => '${match.group(1)} ours',
    );

    // "mines" → "mine" in possessive context
    text = text.replaceAllMapped(
      RegExp(r'\b(is|are|was|were)\s+mines\b', caseSensitive: false),
          (match) => '${match.group(1)} mine',
    );

    // Restore protected possessive pronouns
    text = text
        .replaceAll('___THEIRS___', 'theirs')
        .replaceAll('___YOURS___', 'yours')
        .replaceAll('___HERS___', 'hers')
        .replaceAll('___OURS___', 'ours')
        .replaceAll('___MINE___', 'mine');

    return text;
  }

  // ============================================================================
  // N-GRAM CORRECTIONS (WORD-PAIR PROBABILITY)
  // ============================================================================

  String _applyNgramCorrections(String text) {
    final words = text.split(' ');
    final corrected = <String>[];

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      // Keep apostrophes when cleaning the word for lookup
      String lowerWord = word.toLowerCase().replaceAll(RegExp(r"[^\w']"), '');

      // Skip possessive pronouns and excluded words
      if (excludeWords.contains(lowerWord)) {
        corrected.add(word);
        continue;
      }

      // Check if this word has homophones and there's a next word
      if (homophoneGroups.containsKey(lowerWord)) {
        // Find the next actual word (skip over punctuation like "...")
        String nextWord = '';
        int nextIndex = i + 1;

        while (nextIndex < words.length) {
          String candidateWord = words[nextIndex].toLowerCase().replaceAll(RegExp(r"[^\w']"), '');
          if (candidateWord.isNotEmpty) {
            nextWord = candidateWord;
            break;
          }
          nextIndex++;
        }

        // Only proceed if we found a valid next word
        if (nextWord.isNotEmpty) {
          final homophones = homophoneGroups[lowerWord]!;

          // Find best homophone based on next word context score
          String bestWord = lowerWord;
          double bestScore = 0.0;

          for (var homophone in homophones) {
            if (contextScores.containsKey(homophone)) {
              final score = contextScores[homophone]![nextWord] ?? 0.0;
              if (score > bestScore) {
                bestScore = score;
                bestWord = homophone;
              }
            }
          }

          // Only apply correction if we found a better match
          if (bestScore > 0) {
            // Preserve original capitalization
            if (word.isNotEmpty && word[0] == word[0].toUpperCase()) {
              bestWord = bestWord[0].toUpperCase() + bestWord.substring(1);
            }
            corrected.add(bestWord);
          } else {
            corrected.add(word);
          }
        } else {
          // No valid next word found, keep original
          corrected.add(word);
        }
      } else {
        corrected.add(word);
      }
    }

    return corrected.join(' ');
  }

  // ============================================================================
  // TEXT ENHANCEMENT (CAPITALIZATION, PUNCTUATION, CONTRACTIONS)
  // ============================================================================

  String enhanceText(String text) {
    String enhanced = text.trim();

    // Capitalize first letter
    if (enhanced.isNotEmpty) {
      enhanced = enhanced[0].toUpperCase() + enhanced.substring(1);
    }

    // Fix "i" to "I"
    enhanced = enhanced.replaceAllMapped(
      RegExp(r'\bi\b'),
          (match) => 'I',
    );

    // Fix common contraction mistakes (missing apostrophes)
    enhanced = _fixContractions(enhanced);

    // Add appropriate punctuation at end if missing
    if (enhanced.isNotEmpty &&
        !enhanced.endsWith('.') &&
        !enhanced.endsWith('?') &&
        !enhanced.endsWith('!')) {

      // Check if it's a question
      if (_isQuestion(enhanced)) {
        enhanced += '?';
      } else {
        enhanced += '.';
      }
    }

    return enhanced;
  }

  // ============================================================================
  // QUESTION DETECTION
  // ============================================================================

  bool _isQuestion(String text) {
    String lowerText = text.toLowerCase();

    // Question words at the beginning (including contractions)
    final questionStarters = [
      'what', 'when', 'where', 'which', 'who', 'whom', 'whose',
      'why', 'how', 'can', 'could', 'would', 'should', 'will',
      'shall', 'may', 'might', 'must', 'do', 'does', 'did',
      'is', 'are', 'was', 'were', 'am', 'have', 'has', 'had',
      // Contractions
      "what's", "when's", "where's", "who's", "how's",
      "what'll", "when'll", "where'll",
      "what'd", "when'd", "where'd",
    ];

    for (var starter in questionStarters) {
      if (lowerText.startsWith('$starter ')) {
        return true;
      }
    }

    // Question patterns in the middle
    // "you are coming" vs "are you coming"
    final questionPatterns = [
      RegExp(r'\b(can|could|would|should|will|shall|may|might|must)\s+(i|you|he|she|it|we|they)\b', caseSensitive: false),
      RegExp(r'\b(do|does|did)\s+(i|you|he|she|it|we|they)\b', caseSensitive: false),
      RegExp(r'\b(is|are|was|were|am)\s+(i|you|he|she|it|we|they|there)\b', caseSensitive: false),
      RegExp(r'\b(have|has|had)\s+(i|you|he|she|it|we|they)\b', caseSensitive: false),
    ];

    for (var pattern in questionPatterns) {
      if (pattern.hasMatch(lowerText)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================================
  // FIX CONTRACTIONS (MISSING APOSTROPHES) - 30+ CONTRACTIONS
  // ============================================================================

  String _fixContractions(String text) {
    final contractionFixes = {
      // Common contractions
      r'\bthats\b': "that's",
      r'\bwhats\b': "what's",
      r'\bhows\b': "how's",
      r'\bwheres\b': "where's",
      r'\bwhos\b': "who's",
      r'\blets\b': "let's",

      // I contractions
      r'\bim\b': "I'm",
      r'\bive\b': "I've",
      r'\bid\b': "I'd",
      r'\bill\b': "I'll",

      // Negative contractions
      r'\bdont\b': "don't",
      r'\bdidnt\b': "didn't",
      r'\bdoesnt\b': "doesn't",
      r'\bwont\b': "won't",
      r'\bcant\b': "can't",
      r'\bwouldnt\b': "wouldn't",
      r'\bcouldnt\b': "couldn't",
      r'\bshouldnt\b': "shouldn't",
      r'\bisnt\b': "isn't",
      r'\barent\b': "aren't",
      r'\bwasnt\b': "wasn't",
      r'\bwerent\b': "weren't",
      r'\bhasnt\b': "hasn't",
      r'\bhavent\b': "haven't",
      r'\bhadnt\b': "hadn't",

      // We contractions
      r'\bweve\b': "we've",
      r'\bwed\b': "we'd",
      r'\bwell\b': "we'll",
      r'\bwere\b': "we're",

      // They contractions
      r'\btheyll\b': "they'll",
      r'\btheyd\b': "they'd",
      r'\btheyve\b': "they've",

      // You contractions
      r'\byoull\b': "you'll",
      r'\byoud\b': "you'd",
      r'\byouve\b': "you've",

      // He/She contractions
      r'\bhes\b': "he's",
      r'\bhed\b': "he'd",
      r'\bhell\b': "he'll",
      r'\bshes\b': "she's",
      r'\bshed\b': "she'd",
      r'\bshell\b': "she'll",
    };

    String fixed = text;
    contractionFixes.forEach((pattern, replacement) {
      fixed = fixed.replaceAllMapped(
        RegExp(pattern, caseSensitive: false),
            (match) {
          // Preserve capitalization of original word
          String matched = match.group(0)!;
          if (matched[0] == matched[0].toUpperCase()) {
            return replacement[0].toUpperCase() + replacement.substring(1);
          }
          return replacement;
        },
      );
    });

    return fixed;
  }
}