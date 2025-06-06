(:~
 : Settings for generating a IIIF presentation manifest for a document.
 :)
module namespace iiifc="https://e-editiones.org/api/iiif/config";

import module namespace iiif="https://e-editiones.org/api/iiif" at "lib/api/iiif.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "navigation.xql";
import module namespace ext="http://teipublisher.com/ext-common" at "ext-common.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Base URI of the IIIF image API service to use for the images
 :)
declare variable $iiifc:IMAGE_API_BASE := "https://media.sources-online.org/cantaloupe/iiif/2";

(:~
 : URL prefix to use for the canvas id
 :)
declare variable $iiifc:CANVAS_ID_PREFIX := "https://e-editiones.org/canvas/";

(:~
 : Return all milestone elements pointing to images, usually pb or milestone.
 :
 : @param $doc the document root node to scan
 :)
declare function iiifc:milestones($doc as node()) {
    $doc//tei:surface/tei:graphic
};

(:~
 : Extract the image path from the milestone element. If you need to strip
 : out or add something, this is the place. By default strips any prefix before a colon.
 :)
declare function iiifc:milestone-id($milestone as element()) {
    let $path := $milestone/tei:desc[@subtype='path'][1]/text()
    return fn:encode-for-uri("bullinger!" || replace($path, "/", "!"))
};

(:~
 : Provide general metadata fields for the object. The result will be merged into the
 : root of the presentation manifest. 
 :)
declare function iiifc:metadata($doc as element(), $id as xs:string) as map(*) {
    map {
        "label": ext:get-title($doc),
        "metadata": [
            map { "label": "Title", "value": ext:get-title($doc) },
            map { "label": "Creator", "value": nav:get-metadata($doc, "author")/string() },
            map { "label": "Language", "value": nav:get-metadata($doc, "language") },
            map { "label": "Date", "value": nav:get-metadata($doc, "date")/string() }
        ],
        "license": nav:get-metadata($doc, "license")
        (: "rendering": [
            map {
                "@id": iiif:link("print/" || encode-for-uri($id)),
                "label": "Print preview",
                "format": "text/html"
            },
            map {
                "@id": iiif:link("api/document/" || encode-for-uri($id) || "/epub"),
                "label": "ePub",
                "format": "application/epub+zip"
            }
        ] :)
    }
};