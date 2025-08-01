xquery version "3.1";

module namespace ext="http://teipublisher.com/ext-common";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
(: declare default element namespace "http://www.tei-c.org/ns/1.0"; :)

declare function ext:get-header($letter, $lang-browser as xs:string?) {
    let $root := $letter/ancestor::tei:TEI
    let $senders := ext:correspondents-by-letter($letter, 'sent')
    let $receivers := ext:correspondents-by-letter($letter, 'received')

    let $navigation-item := id($root/@xml:id, doc("/db/apps/bullinger-data/generated/navigation.xml"))
    let $previous-letter := $navigation-item/tei:ptr[@type='prev']/@target
    let $next-letter := $navigation-item/tei:ptr[@type='next']/@target
    let $previous-letter-correspondence := $navigation-item/tei:ptr[@type='prev-same-correspondents']/@target
    let $next-letter-correspondence := $navigation-item/tei:ptr[@type='next-same-correspondents']/@target
    let $type := $letter/ancestor::tei:TEI/@type/string()

    return <div class="top-container">
        <div class="letter-navigation">
            <div class="letter-navigation-inner center-l">
                <span class="letter-navigation-group">
                    <iron-icon class="letter-navigation-group-icon" icon="date-range" aria-hidden="true" fill="currentColor"/>
                    <a class="letter-navigation-link" href="./{$previous-letter}">
                        <iron-icon class="letter-navigation-icon" icon="chevron-left"/>
                        <span class="letter-navigation-tooltip"><pb-i18n key="navigation.previous-letter-by-date">Vorheriger Brief nach Datum</pb-i18n></span>
                    </a>
                    <a class="letter-navigation-link" href="./{$next-letter}">
                        <iron-icon class="letter-navigation-icon" icon="chevron-right"/>
                        <span class="letter-navigation-tooltip"><pb-i18n key="navigation.next-letter-by-date">Nächster Brief nach Datum</pb-i18n></span>
                    </a>
                </span>
                <span class="letter-navigation-group">
                    <iron-icon class="letter-navigation-group-icon" icon="social:people" aria-hidden="true" fill="currentColor"/>
                    <a class="letter-navigation-link" href="./{$previous-letter-correspondence}">
                        <iron-icon class="letter-navigation-icon" icon="chevron-left"/>
                        <span class="letter-navigation-tooltip"><pb-i18n key="navigation.previous-letter-by-correspondents">Vorheriger Brief mit gleichen Korrespondenten</pb-i18n></span>
                    </a>
                    <a class="letter-navigation-link" href="./{$next-letter-correspondence}">
                        <iron-icon class="letter-navigation-icon" icon="chevron-right"/>
                        <span class="letter-navigation-tooltip"><pb-i18n key="navigation.next-letter-by-correspondents">Nächster Brief mit gleichen Korrespondenten</pb-i18n></span>
                    </a>
                </span>
                <span class="letter-navigation-mark-names">
                    <label><input type="checkbox" class="js-entity-checkbox" onclick="javascript:document.body.classList.toggle('colorize-named-entities', this.checked)" /> <pb-i18n key="mark-named-entities">(Namen markieren)</pb-i18n></label>
                </span>
            </div>
        </div>
        <div class="header-container center-l">
            <div>
                <h1>
                    <span style="color:var(--bb-beige);">{$senders}</span>{" "}
                    <pb-i18n key="_to_">(an)</pb-i18n>{" "}
                    <span style="color:var(--bb-beige);">{$receivers}</span>
                </h1>
                <div class="subtitle">
                    <span>
                        <iron-icon id="date-range" icon="date-range" /> {ext:date-by-letter($letter, $lang-browser)}
                        <iron-icon id="map-near-me" icon="maps:near-me" /> {ext:place-name(ext:place-by-letter($letter, 'sent'))}
                    </span>
                    <span class="doc-type {if ($type != 'Brief') then 'doc-type-nonletter' else ''}">
                        <pb-i18n key="metadata.types.{$type}">{$type}</pb-i18n>
                    </span>
                </div>
            </div>
            <div style="flex-shrink: 0;">
                {
                    let $persons := (for $persName in $letter//tei:correspDesc//tei:persName[@ref]
                        group by $persref := $persName/@ref
                        let $person := id($persref, doc('/db/apps/bullinger-data/data/index/persons.xml'))/ancestor::tei:person
                        where $person//tei:idno[@subtype='portrait']
                        return $person)
                    return if (exists($persons)) then
                        <div class="portrait-container">
                            {
                                for $p in $persons
                                let $url := $p//tei:idno[@subtype='portrait']/text()
                                let $id := $p/@xml:id/string()
                                let $title := $p/tei:persName[@type='main']//tei:forename || " " || $p/tei:persName[@type='main']//tei:surname
                                return <div class="portrait">
                                    <a class="portrait__link" href="./persons/{$id}">
                                        <img class="portrait__image" src="resources/portraits/{$url}" alt="{$title}" title="{$title}" />
                                    </a>
                                </div>
                            }
                        </div>
                    else ()
                }
            </div>
        </div>
    </div>
};

declare function ext:metadata-by-letter($letter, $lang-browser as xs:string?) {
    let $root := $letter/ancestor::tei:TEI

    let $regest-source := $root/tei:teiHeader//tei:sourceDesc/tei:bibl[@type='regest']
    let $regest-bibliography := id($regest-source/@source/string(), $config:bibliography)
    let $is-hbbw := if($regest-bibliography/tei:series/text() = 'HBBW') then true() else false()
    let $hbbw-band := if($is-hbbw) then ($regest-bibliography/tei:unit[@type = 'volume']/text()) else ()
    let $hbbw-no := if($is-hbbw) then ($regest-source/@n/string()) else ()
    
    let $languages := for $l in $letter//tei:langUsage/tei:language
        where $l/@usage > 0
        order by $l/@usage div 10 descending
        return <pb-i18n key="metadata.language.{$l/@ident}">({$l/@ident/string()})</pb-i18n>

    return <div>
        <div>
            <div id="sourceDesc">
                <div>
                    <div><pb-i18n key="metadata.date">(Datum)</pb-i18n></div>
                    <div>
                        {
                        let $note := $letter//tei:correspAction[@type='sent']/tei:date/tei:note
                        return <div>
                            {ext:date-by-letter($letter, $lang-browser)}
                            {if (exists($note)) then <pb-popover>
                                <span slot="default"><iron-icon class="metadata-info-icon" id="info-outline" icon="info-outline"/></span>
                                <span slot="alternate">{$note/text()}</span>
                            </pb-popover> else ()}
                        </div>
                        }
                    </div>
                </div>
                <div>
                    <div><pb-i18n key="metadata.sender">(Absender)</pb-i18n></div>
                    <div>{
                        for $i in $letter//tei:correspAction[@type='sent']/*[self::tei:persName or self::tei:orgName or self::tei:roleName]
                        return <div>{ext:correspondent-by-item($i)}</div>
                    }</div>
                </div>
                <div>
                    <div><pb-i18n key="metadata.addressee">(Empfänger)</pb-i18n></div>
                    <div>{
                        for $i in $letter//tei:correspAction[@type='received']/*[self::tei:persName or self::tei:orgName or self::tei:roleName]
                        return <div>{ext:correspondent-by-item($i)}</div>
                    }</div>
                </div>
                {
                    if(exists($letter//tei:correspAction[@type='sent']/tei:placeName)) then
                        <div>
                            <div><pb-i18n key="metadata.place">(Absendeort)</pb-i18n></div>
                            <div>{ext:place-name(ext:place-by-letter($letter, 'sent'))}</div>
                        </div>
                    else ()
                }
                {ext:get-documents-signatures($letter)}
                {
                    if(exists($languages)) then
                        <div>
                            <div><pb-i18n key="metadata.languages">(Sprachen)</pb-i18n></div>
                            <div>
                                {ext:join-sequence(
                                    $languages
                                , ", ")}
                            </div>
                        </div>
                    else ()
                }
                {if (exists($letter//tei:listBibl/tei:bibl[@type='Gedruckt'])) then <div>
                    <div><pb-i18n key="metadata.printed">(Gedruckt in)</pb-i18n></div>
                    <div>
                        <ul>
                            {
                                for $b in $letter//tei:listBibl/tei:bibl where $b/@type = 'Gedruckt' order by fn:starts-with($b/tei:title/text(), 'HBBW') descending
                                return <li>{
                                    if ($b/@subtype != 'Gedruckt' and string-length($b/@subtype) > 0) then
                                        replace($b/@subtype, '__', ' ') || ": " || $b/tei:title/text()
                                    else 
                                        $b/tei:title/text()
                                }</li>
                            }
                        </ul>
                    </div>
                </div> else ()}
                
                {
                    if($is-hbbw) then
                        <div>
                            <div>HBBW-Briefnummer</div>
                            <div>
                                <a target="_blank" href="http://teoirgsed.uzh.ch/SedWEB.cgi?Alias=Briefe&amp;Lng=1&amp;aheight=910&amp;PrjName=Bullinger+-+Briefwechsel&amp;fld_418={replace($hbbw-no, "[^0-9]", "")}">Band {$hbbw-band}, Nr. {$hbbw-no}</a>
                                {
                                    if (fn:matches($hbbw-no, '[a-z]')) then
                                        <pb-popover>
                                            <span slot="default"><iron-icon class="metadata-info-icon" id="info-outline" icon="info-outline"/></span>
                                            <span slot="alternate"><pb-i18n key="metadata.hbbw-link-info" persistent="true">(Um zum richtigen Brief zu gelangen, wählen Sie auf der Zielseite bitte den gewünschten Brief in der linken Spalte aus.)</pb-i18n></span>
                                        </pb-popover>
                                    else ()
                                }
                            </div>
                        </div>
                    else ()
                }

                {
                    let $parents := $letter//tei:correspContext/tei:ref[@type='parent']
                    return if (exists($parents)) then 
                        <div>
                            <div><pb-i18n key="metadata.referenced">(Verweise auf diesen Eintrag)</pb-i18n></div>
                            <div>{ext:get-letter-reference-links($parents)}</div>
                        </div>
                    else ()
                }

                {
                    let $children := $letter//tei:correspContext/tei:ref[@type='child']
                    return if (exists($children)) then 
                        <div>
                            <div><pb-i18n key="metadata.references">(Dieser Eintrag verweist auf)</pb-i18n></div>
                            <div>{ext:get-letter-reference-links($children)}</div>
                        </div>
                    else ()
                }
                
                {
                    let $topic-ids := $letter//tei:encodingDesc//tei:taxonomy/tei:category/@n/string()
                    return if (exists($topic-ids)) then
                        <div>
                            <div><pb-i18n key="metadata.topics">(Themen)</pb-i18n></div>
                            <div>
                                <ul>
                                    {
                                        for $topic-id in $topic-ids
                                        let $topic := id($topic-id, $config:taxonomy)
                                        let $topic-name := (
                                            $topic/tei:catDesc[@xml:lang = $lang-browser]/text(),
                                            $topic/tei:catDesc[1]/text()
                                        )[1]
                                        return <li>{$topic-name}</li>
                                    }
                                </ul>
                            </div>
                        </div>
                    else ()
                }
            </div>
        </div>
    </div>
};

declare function ext:get-letter-reference-links($refs) {
    ext:join-sequence(
        for $ref in $refs
        let $id := fn:replace($ref/@target, 'file', '')
        return <a href="file{$id}">{$id}</a>,
        ', '
    )
};

declare function ext:get-documents-signatures($letter) {
    for $msdesc in $letter//tei:msDesc
    let $text := $msdesc/tei:msIdentifier/tei:idno[@subtype=($msdesc/@subtype)]/text()
    let $note := $msdesc/tei:msIdentifier/tei:idno[@subtype='Hinweis']
    let $subtype := fn:replace($msdesc/@subtype, '__', ' ')
    let $archive-ref := $msdesc//tei:repository/@ref
    let $archive := doc('/db/apps/bullinger-data/data/index/archives.xml')//tei:org[@xml:id=$archive-ref]
    let $era := $msdesc//tei:idno[@subtype='Ära']
    let $author := $msdesc//tei:author
    where string-length($text) > 0
    return <div>
        <div>
            <pb-i18n key="metadata.documents.{$msdesc/@subtype}">({$subtype})</pb-i18n>
        </div>
        <div>
            {
                if(exists($archive)) then
                    (<a href="{$archive/tei:idno[@subtype='url']}">{$archive/tei:orgName}</a>, ", ")
                else ()
            }
            {$text}
            {if (exists($era)) then (" (", $era, ")") else ()}
            {if (exists($note) or exists($author)) then 
                <pb-popover>
                    <span slot="default"><iron-icon class="metadata-info-icon" title="Hinweis" id="info-outline" icon="info-outline"/></span>
                    <span slot="alternate">
                        {$note}
                        {if (exists($author)) then
                            <div>
                                <pb-i18n key="metadata.author">(Hand von:)</pb-i18n>
                                {" " || $author}
                            </div>
                        else ()}
                    </span>
                </pb-popover>
            else ()}
        </div>
    </div>
};

(: Helper function to join a sequence of elements with a separator :)
declare function ext:join-sequence($items as element()*, $separator as xs:string) {
    for $e at $i in $items
    return 
        if ($i eq 1) then $e
        else ($separator, $e)
};

declare function ext:get-title($letter) {
    let $senders := ext:correspondents-by-letter($letter, 'sent')
    let $receivers := ext:correspondents-by-letter($letter, 'received')
    return $senders || " an " || $receivers
};

(: $type should be either 'sent' or 'received :)
declare function ext:correspondents-by-letter($letter, $type as xs:string) {
    let $text := $letter//tei:correspAction[@type = $type]/tei:rs
    return if(fn:string-length($text) > 0) then
        $text/text()
    else
        let $items := for $item in $letter//tei:correspAction[@type = $type]/*[self::tei:persName or self::tei:orgName or self::tei:roleName]
            order by $item
            return ext:correspondent-by-item($item, true())
        let $correspondents := string-join($items, ', ')
        return if(fn:string-length($correspondents) > 0) then
            $correspondents
        else
            "[...]"
};

declare function ext:correspondent-by-item($item) {
    ext:correspondent-by-item($item, false())
};

(: Item should be one of persName, orgName, roleName :)
declare function ext:correspondent-by-item($item, $persname-remove-brackets as xs:boolean) {
    typeswitch ($item)
        case element(tei:persName) return
            let $person := id(upper-case($item/@ref), $config:persons)
            let $persName := $person/tei:persName[@type='main']
            let $name := $persName/tei:forename || " " || $persName/tei:surname
            (: Remove brackets if required :)
            let $display-name := if($persname-remove-brackets) then
                fn:replace(fn:replace($name, '\s*\(.*?\)', ''), '\s*\[.*?\]', '')
            else
                $name
            return
                <a href="./persons/{upper-case($item/@ref)}">{$display-name}</a>
        case element(tei:orgName) return
            if(fn:string-length($item/text()) > 0) then
                ($item/text())
            else (id($item/@ref, $config:orgs)/string())
        default return
            "[...]"
};

declare function ext:date-by-letter($item, $lang-browser as xs:string?) {
    let $lang := if(starts-with($lang-browser, 'de')) then 'de' else 'en'
    
    let $date := typeswitch($item)
        case element(tei:correspAction) return $item/tei:date
        default return $item//tei:correspAction[@type = "sent"]/tei:date
    return if(fn:string-length($date/text()) > 0) then
        $date/text()
    else if(exists($date/@when)) then
        ext:format-date($date/@when, $lang)
    else if (exists($date/@notBefore) and exists($date/@notAfter)) then
        (
            <pb-i18n key="dates.between">(Between)</pb-i18n>,
            " ",
            ext:format-date($date/@notBefore, $lang),
            " ",
            <pb-i18n key="dates.and">(und)</pb-i18n>,
            " ", 
            ext:format-date($date/@notAfter, $lang)
        )
    else if(exists($date/@notBefore)) then
        (
            <pb-i18n key="dates.after">(Nach)</pb-i18n>,
            " ",
            ext:format-date($date/@notBefore, $lang)
        )
    else if(exists($date/@notAfter)) then
        (
            <pb-i18n key="dates.before">(Vor)</pb-i18n>,
            " ",
            ext:format-date($date/@notAfter, $lang)
        )
    else
        <pb-i18n key="dates.unknown">(Unbekannt)</pb-i18n>
};

declare function ext:format-date($date as xs:string?, $lang as xs:string){
    if(string-length($date) = 0) then
        ()
    else if(matches($date, '^\d{4}$')) then
        $date
    else if (matches($date, '^\d{4}-\d{2}$')) then
        format-date(xs:date($date || '-01'), '[MNn] [Y]', $lang, (), ())
    else if (matches($date, '^\d{4}-\d{2}-\d{2}$')) then
        format-date(xs:date($date), '[D]. [MNn] [Y]', $lang, (), ())
    else
        $date
};


declare function ext:place-name($place) {
    let $settlement := $place//tei:settlement/text()
    let $district := $place//tei:district/text()
    let $country := $place//tei:country/text()
    let $place-name := if($settlement) then
            ($settlement)
        else if ($district) then
            ($district)
        else if ($country) then
            ($country)
        else ("[...]")
    return $place-name
};

declare function ext:place-by-letter($letter, $type as xs:string) {
    let $place-id := $letter//tei:correspAction[@type = $type]/tei:placeName/@ref
    return id($place-id, $config:localities)
};

declare function ext:place-by-letter($letter) {
    ext:place-by-letter($letter, 'sent')
};

(: Converts a polygon string to an array of coordinaates in the format [x, y, w, h] :)
declare function ext:convert-polygon-to-coordinates($polygon as xs:string) {
    let $points := tokenize($polygon, '\s+')
    let $x-values := for $p in $points return number(tokenize($p, ',')[1])
    let $y-values := for $p in $points return number(tokenize($p, ',')[2])
    let $x-min := min($x-values)
    let $x-max := max($x-values)
    let $y-min := min($y-values)
    let $y-max := max($y-values)
    let $width := $x-max - $x-min
    let $height := $y-max - $y-min
    return concat("[", $x-min, ", ", $y-min, ", ", $width, ", ", $height, "]")
};