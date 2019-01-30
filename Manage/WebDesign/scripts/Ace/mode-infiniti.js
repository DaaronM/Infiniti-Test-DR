define("ace/mode/infiniti_highlight_rules", ["require", "exports", "module", "ace/lib/oop", "ace/mode/text_highlight_rules"],
    function (e, t, n) {
        "use strict"; var r = e("../lib/oop"), i = e("./text_highlight_rules").TextHighlightRules,
            s = function () {
                var e = this.createKeywordMapper({
                    "keyword.operator.asp": "Mod",
                    "support.function": 'Abs|Average|Chr|Concat|Contains|Count|CountIf|CountNumber|DateAdd|DateDiff|EndsWith|ErrorMask|First|Format|' +
                          'IIf|IsEqual|IsGreaterThan|IsGreaterThanOrEqualTo|IsLessThan|IsLessThanOrEqualTo|IsNotEqual|IsTrue|' +
                          'Join|JoinAnd|Last|Left|Len|Length|LocalToUtc|Max|Min|NotContains|Now|ProperCase|RangeIndex|Replace|Right|Round|Today|' +
                          'StartsWith|StringContains|Substring|Sum|Trim|UtcNow|UtcToday|UtcToLocal'
                }, "identifier", !0);
                this.$rules = {
                    start: [{
                        token: [null], regex: "^(?=\\t)", next: "state_3"
                    }, {
                        token: [null], regex: "^(?= )", next: "state_4"
                    }, {
                        token: "punctuation.definition.comment.asp", regex: "'|REM(?=\\s|$)", next: "comment", caseInsensitive: !0
                    }, {
                        token: "reference", regex: '\\[', next: 'reference'
                    }, {
                        token: "punctuation.definition.string.begin.asp", regex: '"', next: "string"
                    }, {
                        token: "constant.numeric.asp",
                        regex: "-?\\b(?:(?:0(?:x|X)[0-9a-fA-F]*)|(?:(?:[0-9]+\\.?[0-9]*)|(?:\\.[0-9]+))(?:(?:e|E)(?:\\+|-)?[0-9]+)?)(?:L|l|UL|ul|u|U|F|f)?\\b"
                    }, { regex: "\\w+", token: e }, {
                        token: ["entity.name.function.asp"],
                        regex: "(?:(\\b[a-zA-Z_x7f-xff][a-zA-Z0-9_x7f-xff]*?\\b)(?=\\(\\)?))"
                    }, { token: ["keyword.operator.asp"], regex: "\\-|\\+|\\*\\/|\\>|\\<|\\=|\\&" }],
                    state_3: [{
                        token: ["meta.odd-tab.tabs", "meta.even-tab.tabs"], regex: "(\\t)(\\t)?"
                    }, {
                        token: "meta.leading-space", regex: "(?=[^\\t])", next: "start"
                    }, {
                        token: "meta.leading-space", regex: ".", next: "state_3"
                    }],
                    state_4: [{ token: ["meta.odd-tab.spaces", "meta.even-tab.spaces"], regex: "(  )(  )?" }, {
                        token: "meta.leading-space",
                        regex: "(?=[^ ])", next: "start"
                    }, { defaultToken: "meta.leading-space" }], comment: [{
                        token: "comment.line.apostrophe.asp",
                        regex: "$|(?=(?:%>))", next: "start"
                    }, { defaultToken: "comment.line.apostrophe.asp" }],
                    reference: [{
                        token: "reference", regex: '\\]', next: "start"
                    },
                    { defaultToken: "reference" }],
                    string: [{ token: "constant.character.escape.apostrophe.asp", regex: '""' },
                        {
                            token: "string.quoted.double.asp", regex: '"', next: "start"
                        },
                    { defaultToken: "string.quoted.double.asp" }]
                }
            }; r.inherits(s, i), t.InfinitiHighlightRules = s
    }), define("ace/mode/infiniti", ["require", "exports", "module", "ace/lib/oop", "ace/mode/text", "ace/mode/infiniti_highlight_rules"],
    function (e, t, n) {
        "use strict"; var r = e("../lib/oop"), i = e("./text").Mode, s = e("./infiniti_highlight_rules").InfinitiHighlightRules,
            o = function () { this.HighlightRules = s }; r.inherits(o, i), function () { this.lineCommentStart = ["'", "REM"], this.$id = "ace/mode/infiniti" }.call(o.prototype), t.Mode = o
    })
