---
title: "Bookmarklet for RationalWiki"
bookmarklet of: RationalWiki
description: >-
  This bookmarklet creates a set of YAML front matter based on the current rationalwiki.org page. To use, save the bookmarklet on the bookmarks toolbar of your browser. The toolbar allows you to access the bookmarklet as a button. Then, navigate to a page on rationalwiki.org and click the button. The bookmarklet will generate YAML front matter and copy to the clipboard. If you get an error, try again. There is a known issue when the page does not have focus.
license: public domain
modified version of: Bookmarklet for Wikipedia
note: >-
  This is a copy of the Wikimedia bookmarklet, modified for rationalwiki.org.
when: 2026-07-04
tags:
  - generative AI
---

```javascript
javascript:(async function(){
  try{
    /* Ensure this is a RationalWiki article */
    if(!location.hostname.includes("rationalwiki.org")||!location.pathname.startsWith("/wiki/")){
      alert("This only works on rationalwiki.org article pages.");
      return;
    }

    /* Extract title */
    var titleEl=document.getElementById("firstHeading");
    var title=titleEl?titleEl.innerText.trim():"";

    /* Extract first non-empty paragraph element */
    var firstPara="";
    var firstParaEl=null;
    var content=document.getElementById("mw-content-text");
    if(content){
      var ps=content.querySelectorAll("p");
      for(var i=0;i<ps.length;i++){
        var t=ps[i].innerText.trim();
        if(t){
          firstParaEl=ps[i];
          firstPara=t;
          break;
        }
      }
    }

    /* Find bolded article name and convert to Markdown ** */
    if(firstParaEl){
      var boldEl=firstParaEl.querySelector("b,strong");
      if(boldEl){
        var boldText=boldEl.innerText.trim();
        var safeBoldText=boldText.replace(/[.*+?^${}()|[\]\\]/g,"\\$&"); /* escape regex */
        firstPara=firstPara.replace(new RegExp(safeBoldText),"**"+boldText+"**");
      }
    }

    /* Remove footnote markers like [1], [a], [12] */
    firstPara=firstPara.replace(/\[\s*[^\]]+?\s*\]/g,"");

    /* Normalize whitespace */
    firstPara=firstPara.replace(/\s+/g," ").trim();

    /* Format LOCAL date YYYY-MM-DD */
    var d=new Date();
    var date=d.getFullYear()+"-"
      +String(d.getMonth()+1).padStart(2,"0")+"-"
      +String(d.getDate()).padStart(2,"0");

    /* Build path */
    var wikiPath=location.pathname.replace(/^\/wiki\//,"");

    /* Full website URL */
    var fullUrl="https://"+location.hostname+location.pathname;

    /* Build YAML */
    var yaml="---\n"
      +"title: \""+title+" (rationalwiki.org)\"\n"
      +"excerpt: >-\n"
      +"  "+firstPara.replace(/\n/g,"\n  ")+"\n"
      +"license: CC BY-SA 3.0\n"
      +"rationalwiki of: "+title+"\n"
      +"retrieved: "+date+"\n"
      +"type: website\n"
      +"url: /"+location.hostname+"/wiki/"+wikiPath+"/\n"
      +"website: \""+fullUrl+"\"\n"
      +"tags:\n"
      +"  - website\n"
      +"  - RationalWiki\n"
      +"---";

    await navigator.clipboard.writeText(yaml);
    alert("YAML copied to clipboard ✅");

  }catch(e){
    console.error(e);
    alert("Failed to generate YAML.");
  }
})();void(0);
```