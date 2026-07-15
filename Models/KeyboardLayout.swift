import Foundation

// MARK: - 五笔86 键盘布局与参考数据

/// 字根键盘信息
struct KeyInfo {
    let key: String       // 字母键
    let zone: Int         // 分区 (1-5)
    let pos: Int          // 区内位置 (1-5)
    let name: String      // 键名
    let roots: String     // 字根
    let recognitionCode: String // 识别码
}

/// 五笔86 键盘布局、简码与参考数据
enum KeyboardLayout {
    /// 键盘行布局
    static let rows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
    ]

    /// 分区名称
    static let zoneNames: [Int: String] = [
        1: "横区 (ASDFG)",
        2: "竖区 (HJKLM)",
        3: "撇区 (TREWQ)",
        4: "捺区 (YUIOP)",
        5: "折区 (NBVCX)",
    ]

    /// 字根键盘详细数据
    static let keyboard: [String: KeyInfo] = [
        "a": KeyInfo(key: "a", zone: 1, pos: 5, name: "工", roots: "               ", recognitionCode: ""),
        "b": KeyInfo(key: "b", zone: 5, pos: 2, name: "子", roots: "              ", recognitionCode: "⿱"),
        "c": KeyInfo(key: "c", zone: 5, pos: 4, name: "又", roots: "       ", recognitionCode: ""),
        "d": KeyInfo(key: "d", zone: 1, pos: 3, name: "大", roots: "             ", recognitionCode: "⿻"),
        "e": KeyInfo(key: "e", zone: 3, pos: 3, name: "月", roots: "                  ", recognitionCode: "⿻"),
        "f": KeyInfo(key: "f", zone: 1, pos: 2, name: "土", roots: "           ", recognitionCode: "⿱"),
        "g": KeyInfo(key: "g", zone: 1, pos: 1, name: "王", roots: "      ", recognitionCode: "⿰"),
        "h": KeyInfo(key: "h", zone: 2, pos: 1, name: "目", roots: "          ", recognitionCode: "⿰"),
        "i": KeyInfo(key: "i", zone: 4, pos: 3, name: "水", roots: "                  ", recognitionCode: "⿻"),
        "j": KeyInfo(key: "j", zone: 2, pos: 2, name: "日", roots: "             ", recognitionCode: "⿱"),
        "k": KeyInfo(key: "k", zone: 2, pos: 3, name: "口", roots: "  ", recognitionCode: "⿻"),
        "l": KeyInfo(key: "l", zone: 2, pos: 4, name: "田", roots: "             〇", recognitionCode: ""),
        "m": KeyInfo(key: "m", zone: 2, pos: 5, name: "山", roots: "               ", recognitionCode: ""),
        "n": KeyInfo(key: "n", zone: 5, pos: 1, name: "已", roots: "                                       ", recognitionCode: "⿰"),
        "o": KeyInfo(key: "o", zone: 4, pos: 4, name: "火", roots: "       ", recognitionCode: ""),
        "p": KeyInfo(key: "p", zone: 4, pos: 5, name: "之", roots: "     ", recognitionCode: ""),
        "q": KeyInfo(key: "q", zone: 3, pos: 5, name: "金", roots: "                     ", recognitionCode: ""),
        "r": KeyInfo(key: "r", zone: 3, pos: 2, name: "白", roots: "         ", recognitionCode: "⿱"),
        "s": KeyInfo(key: "s", zone: 1, pos: 4, name: "木", roots: "     ", recognitionCode: ""),
        "t": KeyInfo(key: "t", zone: 3, pos: 1, name: "禾", roots: "          ", recognitionCode: "⿰"),
        "u": KeyInfo(key: "u", zone: 4, pos: 2, name: "立", roots: "              ", recognitionCode: "⿱"),
        "v": KeyInfo(key: "v", zone: 5, pos: 3, name: "女", roots: "        ", recognitionCode: "⿻"),
        "w": KeyInfo(key: "w", zone: 3, pos: 4, name: "人", roots: "      ", recognitionCode: ""),
        "x": KeyInfo(key: "x", zone: 5, pos: 5, name: "纟", roots: "             ", recognitionCode: ""),
        "y": KeyInfo(key: "y", zone: 4, pos: 1, name: "言", roots: "            ", recognitionCode: "⿰"),
        "z": KeyInfo(key: "z", zone: 0, pos: 0, name: "学", roots: "学习键", recognitionCode: ""),
    ]

    /// 键位顺序（用于字根表渲染）
    static let keyOrder: [String] = [
        "g", "f", "d", "s", "a",
        "h", "j", "k", "l", "m",
        "t", "r", "e", "w", "q",
        "y", "u", "i", "o", "p",
        "n", "b", "v", "c", "x",
    ]

    /// 一级简码（25 个）
    static let yijianJianma: [String: String] = [
        "a": "工",
        "b": "了",
        "c": "以",
        "d": "在",
        "e": "有",
        "f": "地",
        "g": "一",
        "h": "上",
        "i": "不",
        "j": "是",
        "k": "中",
        "l": "国",
        "m": "同",
        "n": "民",
        "o": "为",
        "p": "这",
        "q": "我",
        "r": "的",
        "s": "要",
        "t": "和",
        "u": "产",
        "v": "发",
        "w": "人",
        "x": "经",
        "y": "主",
    ]

    /// 二级简码（常见字）
    static let erjianJianma: [String: String] = [
        "ag": "七",
        "aj": "东",
        "bn": "了",
        "cb": "戏",
        "dd": "大",
        "dg": "三",
        "ee": "月",
        "et": "用",
        "fg": "十",
        "fh": "二",
        "gd": "天",
        "gg": "一",
        "gh": "王",
        "gm": "天",
        "gs": "五",
        "ic": "汉",
        "ip": "学",
        "je": "明",
        "jf": "时",
        "kh": "中",
        "lh": "四",
        "mh": "山",
        "mt": "几",
        "mw": "内",
        "nb": "民",
        "nm": "忌",
        "nt": "改",
        "oy": "米",
        "pg": "字",
        "qt": "狗",
        "rj": "打",
        "rn": "气",
        "rp": "抽",
        "sg": "本",
        "tf": "行",
        "uj": "间",
        "uk": "问",
        "uy": "六",
        "vb": "好",
        "vt": "九",
        "wg": "从",
        "wq": "你",
        "ww": "八",
        "xe": "红",
        "yy": "方",
    ]

    /// 按分区分类的常用字
    static let zoneChars: [Int: [String]] = [
        1: ["王", "一", "五", "土", "十", "二", "干", "大", "三", "古", "石", "木", "丁", "西", "工", "七", "地", "本", "在", "有", "不", "未", "末", "平", "来", "事", "天", "无", "而", "下", "于", "丰", "百", "左", "右", "布", "太", "达", "奋", "磊", "万", "确", "百", "林"],
        2: ["目", "上", "止", "日", "早", "口", "田", "山", "中", "时", "明", "国", "里", "电", "由", "内", "见", "足", "思", "量", "品", "哭", "骂", "吃", "吐", "叶", "号", "另", "加", "占", "台", "吊", "叹", "兄", "呆", "昌", "晨", "暗", "照", "影", "路", "骨", "回", "果", "史", "四", "甲", "车", "力", "加"],
        3: ["禾", "竹", "白", "手", "月", "人", "金", "我", "他", "的", "和", "你", "她", "得", "很", "行", "往", "征", "必", "毛", "气", "千", "乘", "释", "拜", "看", "后", "质", "打", "找", "把", "排", "推", "持", "特", "告", "先", "入", "认", "钱", "铁", "钢", "针", "种", "积", "秀", "程", "称", "稿", "税"],
        4: ["言", "文", "立", "水", "火", "之", "说", "话", "这", "方", "主", "意", "前", "信", "认", "让", "就", "学", "问", "记", "该", "讲", "议", "论", "试", "读", "写", "交", "市", "京", "六", "辛", "门", "病", "州", "头", "买", "冰", "注", "海", "清", "法", "河", "活", "汉", "江", "油", "演", "满", "点"],
        5: ["已", "子", "女", "又", "弓", "也", "了", "那", "民", "出", "能", "对", "发", "以", "好", "如", "她", "妈", "妇", "怒", "忍", "飞", "杂", "纪", "红", "级", "丝", "经", "约", "弱", "强", "引", "张", "弹", "观", "孙", "取", "受", "改", "防", "阳", "阶", "队", "阵", "降", "除", "隐", "难", "邓", "建"],
    ]

    /// 获取键的所属分区
    static func zone(for key: String) -> Int {
        keyboard[key]?.zone ?? 0
    }

    /// 获取分区的键列表
    static func keys(in zone: Int) -> [String] {
        keyboard.filter { $0.value.zone == zone }.map(\.key).sorted {
            (keyboard[$0]?.pos ?? 0) < (keyboard[$1]?.pos ?? 0)
        }
    }
}
