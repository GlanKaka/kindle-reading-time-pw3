(function () {
"use strict";

var source=window.READING_DATA||{entries:[],progress:[],generatedAt:""};
var entries=source.entries||[],progress=source.progress||[];
var dates={},books={},progressById={},progressByTitle={};
var totalSeconds=0,readingDays=0,chartViewYear,calendarYear,calendarMonth,selectedDate,bookPage=1;
var now=new Date(),today=dateKey(now.getFullYear(),now.getMonth()+1,now.getDate());

function byId(id){return document.getElementById(id)}
function text(node,value){if(node){if(typeof node.textContent!=="undefined"){node.textContent=value}else{node.innerText=value}}}
function pad(n){return n<10?"0"+n:""+n}
function dateKey(y,m,d){return y+"-"+pad(m)+"-"+pad(d)}
function escapeHtml(value){return String(value).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;")}
function formatTime(seconds){
    seconds=Math.max(0,Math.round(seconds||0));
    var h=Math.floor(seconds/3600),m=Math.floor((seconds%3600)/60),s=seconds%60,out="";
    if(h){out+=h+"小时"}if(m){out+=m+"分钟"}if(s||!out){out+=s+"秒"}return out;
}
function daysInMonth(y,m){return new Date(y,m,0).getDate()}
function firstWeekday(y,m){var d=new Date(y,m-1,1).getDay();return d===0?6:d-1}
function setClass(node,value){if(node){node.className=value}}
function bind(node,fn){if(!node){return}if(node.addEventListener){node.addEventListener("click",fn,false)}else{node.onclick=fn}}

function prepareData(){
    var i,e,key,b,p,title;
    for(i=0;i<progress.length;i++){
        p=progress[i];
        if(p[0]){progressById[p[0]]=p[2]}
        if(p[1]){progressByTitle[p[1]]=p[2]}
    }
    for(i=0;i<entries.length;i++){
        e=entries[i];
        if(!e||e.length<4){continue}
        if(!dates[e[0]]){dates[e[0]]={seconds:0,books:{}}}
        dates[e[0]].seconds+=Number(e[2])||0;
        key=e[1]&&e[1]!=="unknown"?"id:"+e[1]:"title:"+e[3];
        if(!dates[e[0]].books[key]){dates[e[0]].books[key]={title:e[3],seconds:0}}
        dates[e[0]].books[key].seconds+=Number(e[2])||0;
        if(!books[key]){books[key]={id:e[1],title:e[3],seconds:0,firstDate:e[0]}}
        books[key].seconds+=Number(e[2])||0;
        if(e[0]<books[key].firstDate){books[key].firstDate=e[0]}
        totalSeconds+=Number(e[2])||0;
    }
    for(key in dates){if(Object.prototype.hasOwnProperty.call(dates,key)&&dates[key].seconds>0){readingDays++}}
    for(key in books){
        if(Object.prototype.hasOwnProperty.call(books,key)){
            b=books[key];title=b.title||"未知书籍";
            if(b.id&&typeof progressById[b.id]!=="undefined"){b.percent=progressById[b.id]}
            else if(typeof progressByTitle[title]!=="undefined"){b.percent=progressByTitle[title]}
            else{b.percent=null}
        }
    }
}

function show(name){
    var names=["total","daily","books"],tabs=document.getElementsByClassName("tab"),i,page;
    for(i=0;i<names.length;i++){
        page=byId(names[i]);
        setClass(page,"page"+(names[i]==="books"?" books-page":"")+(names[i]===name?" visible":""));
    }
    for(i=0;i<tabs.length;i++){
        setClass(tabs[i],"tab"+(i===2?" tab-last":"")+(tabs[i].getAttribute("data-page")===name?" selected":""));
    }
    if(name==="total"){renderTotal()}else if(name==="daily"){renderDaily()}else{renderBooks()}
}

function maxValue(values){var i,max=0;for(i=0;i<values.length;i++){if(values[i]>max){max=values[i]}}return max}
function renderBars(target,values,className,currentIndex){
    var max=maxValue(values),html="",i,height,label;
    for(i=0;i<values.length;i++){
        height=max?Math.max(2,Math.round(values[i]*92/max)):2;
        label=values[i]?formatTime(values[i]):"";
        html+='<span class="'+className+(i===currentIndex?' current':'')+'" style="height:'+height+'%"><em>'+escapeHtml(label)+'</em></span>';
    }
    byId(target).innerHTML=html;
}
function renderTotal(){
    var months=[],week=[],monthLabels="",weekLabels="",i,key,day,monday,currentWeek=-1;
    text(byId("totalTime"),formatTime(totalSeconds));
    text(byId("totalDays"),readingDays+"天");
    text(byId("dailyAverage"),formatTime(readingDays?Math.round(totalSeconds/readingDays):0));
    text(byId("chartYear"),chartViewYear+"年");
    for(i=1;i<=12;i++){
        months[i-1]=0;monthLabels+="<span>"+i+"月</span>";
    }
    for(key in dates){if(Object.prototype.hasOwnProperty.call(dates,key)&&Number(key.substr(0,4))===chartViewYear){months[Number(key.substr(5,2))-1]+=dates[key].seconds}}
    renderBars("chart",months,"bar",chartViewYear===now.getFullYear()?now.getMonth():-1);
    byId("months").innerHTML=monthLabels;
    day=new Date(now.getFullYear(),now.getMonth(),now.getDate());
    monday=new Date(day.getFullYear(),day.getMonth(),day.getDate()-((day.getDay()+6)%7));
    for(i=0;i<7;i++){
        day=new Date(monday.getFullYear(),monday.getMonth(),monday.getDate()+i);
        key=dateKey(day.getFullYear(),day.getMonth()+1,day.getDate());
        week[i]=dates[key]?dates[key].seconds:0;
        if(key===today){currentWeek=i}
        weekLabels+="<span>"+["周一","周二","周三","周四","周五","周六","周日"][i]+"</span>";
    }
    renderBars("weekChart",week,"week-bar",currentWeek);
    byId("weekDays").innerHTML=weekLabels;
    text(byId("weekAverage"),formatTime(Math.round((week[0]+week[1]+week[2]+week[3]+week[4]+week[5]+week[6])/7)));
}

function renderCalendar(){
    var start=firstWeekday(calendarYear,calendarMonth),count=daysInMonth(calendarYear,calendarMonth),cells=Math.ceil((start+count)/7)*7;
    var html="",cell,day,key,item,reading;
    text(byId("calendarMonth"),calendarYear+"年"+calendarMonth+"月");
    for(cell=0;cell<cells;cell++){
        if(cell%7===0){html+="<tr>"}
        day=cell-start+1;
        if(day<1||day>count){html+="<td></td>"}
        else{
            key=dateKey(calendarYear,calendarMonth,day);item=dates[key];reading=item&&item.seconds?formatTime(item.seconds):"";
            html+='<td><button type="button" class="day'+(key===selectedDate?' selected':'')+'" data-date="'+key+'"><span class="day-number">'+day+'</span><span class="day-reading">'+escapeHtml(reading)+'</span></button></td>';
        }
        if(cell%7===6){html+="</tr>"}
    }
    byId("calendarBody").innerHTML=html;
    item=document.getElementsByClassName("day");
    for(cell=0;cell<item.length;cell++){bind(item[cell],function(){selectedDate=this.getAttribute("data-date");renderCalendar();renderDayDetail()})}
    reading=0;
    for(key in dates){if(Object.prototype.hasOwnProperty.call(dates,key)&&Number(key.substr(0,4))===calendarYear&&Number(key.substr(5,2))===calendarMonth&&dates[key].seconds>0){reading++}}
    text(byId("monthDays"),"本月阅读 "+reading+" 天");
}
function renderDayDetail(){
    var item=dates[selectedDate],list=[],key,html="",i,parts=selectedDate.split("-");
    text(byId("detailDate"),Number(parts[1])+"月"+Number(parts[2])+"日 阅读详情");
    text(byId("detailTotal"),"共 "+formatTime(item?item.seconds:0));
    if(item){for(key in item.books){if(Object.prototype.hasOwnProperty.call(item.books,key)){list.push(item.books[key])}}}
    list.sort(function(a,b){return b.seconds-a.seconds});
    if(!list.length){html='<div class="empty">这一天还没有阅读记录</div>'}
    else{for(i=0;i<list.length;i++){html+='<div class="detail-row"><span>'+escapeHtml(list[i].title)+'</span><b>'+escapeHtml(formatTime(list[i].seconds))+'</b></div>'}}
    byId("detailBooks").innerHTML=html;
}
function renderDaily(){renderCalendar();renderDayDetail()}

function bookArray(){
    var list=[],key;
    for(key in books){if(Object.prototype.hasOwnProperty.call(books,key)){list.push(books[key])}}
    list.sort(function(a,b){if(b.seconds!==a.seconds){return b.seconds-a.seconds}return a.firstDate<b.firstDate?-1:1});
    return list;
}
function setDisabled(node,disabled){if(!node){return}node.disabled=disabled;setClass(node,disabled?"disabled":"")}
function renderBooks(){
    var list=bookArray(),pages=Math.max(1,Math.ceil(list.length/4)),start,i,b,percent,label,html="";
    if(bookPage>pages){bookPage=pages}if(bookPage<1){bookPage=1}start=(bookPage-1)*4;
    for(i=start;i<Math.min(start+4,list.length);i++){
        b=list[i];percent=b.percent===null?0:Math.max(0,Math.min(100,b.percent));label=b.percent===null?"进度未知":percent+"%";
        html+='<div class="book-row"><strong>'+(i+1)+'. '+escapeHtml(b.title)+'</strong><div class="book-progress-meta"><span>阅读 '+escapeHtml(formatTime(b.seconds))+'</span><em>'+escapeHtml(label)+'</em></div><div class="book-progress"><i style="width:'+percent+'%"></i></div></div>';
    }
    if(!list.length){html='<div class="empty">还没有阅读记录</div>'}
    byId("bookRows").innerHTML=html;
    text(byId("bookPage"),list.length?"第 "+bookPage+" 页，共 "+pages+" 页":"共 0 本");
    setDisabled(byId("bookPrev"),bookPage<=1);setDisabled(byId("bookNext"),bookPage>=pages);
}

function ready(){
    var tabs=document.getElementsByClassName("tab"),i;
    prepareData();chartViewYear=now.getFullYear();calendarYear=now.getFullYear();calendarMonth=now.getMonth()+1;selectedDate=today;
    for(i=0;i<tabs.length;i++){bind(tabs[i],function(){show(this.getAttribute("data-page"))})}
    bind(byId("yearPrev"),function(){chartViewYear--;renderTotal()});bind(byId("yearNext"),function(){chartViewYear++;renderTotal()});
    bind(byId("monthPrev"),function(){calendarMonth--;if(calendarMonth<1){calendarMonth=12;calendarYear--}selectedDate=dateKey(calendarYear,calendarMonth,1);renderDaily()});
    bind(byId("monthNext"),function(){calendarMonth++;if(calendarMonth>12){calendarMonth=1;calendarYear++}selectedDate=dateKey(calendarYear,calendarMonth,1);renderDaily()});
    bind(byId("bookPrev"),function(){if(bookPage>1){bookPage--;renderBooks()}});bind(byId("bookNext"),function(){var pages=Math.max(1,Math.ceil(bookArray().length/4));if(bookPage<pages){bookPage++;renderBooks()}});
    text(byId("updated"),"更新于 "+(source.generatedAt||"未知时间")+" · 动态单页面版");show("total");
}
if(document.addEventListener){document.addEventListener("DOMContentLoaded",ready,false)}else{window.onload=ready}
}());
