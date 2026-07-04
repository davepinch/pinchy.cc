---
title: "Bookmarklet for Wikipedia"
bookmarklet of: Wikipedia
license:
  - public domain
  - As a policy, anything created with generative AI is disclosed and licensed as public domain. Licensing should be public domain because the AI is based on the combined output of all people.
note: >-
  I used Copilot to generate a bookmarklet that extracts Wikipedia information to the front matter format used by this blog. It was surprisingly easy and only took a few iterations. Most of these iterations were due to oversights on my part when writing the initial prompt.
when: 2026-06-21
tags:
  - generative AI
---

```javascript
javascript:(async function(){
  try{
    /* Ensure this is a Wikipedia article */
    if(!location.hostname.includes("wikipedia.org")||!location.pathname.startsWith("/wiki/")){
      alert("This only works on Wikipedia article pages.");
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
      +"title: \""+title+" (Wikipedia)\"\n"
      +"excerpt: >-\n"
      +"  "+firstPara.replace(/\n/g,"\n  ")+"\n"
      +"license: CC BY-SA 4.0\n"
      +"retrieved: "+date+"\n"
      +"type: website\n"
      +"url: /"+location.hostname+"/wiki/"+wikiPath+"/\n"
      +"website: \""+fullUrl+"\"\n"
      +"wikipedia of: "+title+"\n"
      +"tags:\n"
      +"  - Wikipedia\n"
      +"---";

    await navigator.clipboard.writeText(yaml);
    alert("YAML copied to clipboard ✅");

  }catch(e){
    console.error(e);
    alert("Failed to generate YAML.");
  }
})();void(0);
```