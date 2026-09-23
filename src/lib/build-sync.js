const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));

export function currentBuildId(){
  return document.querySelector('meta[name="build-id"]')?.content||null;
}

export async function fetchBuildId(path='/admin'){
  try{
    const separator=path.includes('?')?'&':'?';
    const response=await fetch(path+separator+'build-check='+Date.now(),{
      cache:'no-store',
      credentials:'same-origin'
    });
    if(!response.ok)return null;
    const html=await response.text();
    return new DOMParser().parseFromString(html,'text/html')
      .querySelector('meta[name="build-id"]')?.content||null;
  }catch{
    return null;
  }
}

export async function getBuildBaseline(path='/admin'){
  return currentBuildId()||await fetchBuildId(path);
}

export async function waitForRebuild(previousBuildId,{
  path='/admin',
  intervalMs=5000,
  maxAttempts=36
}={}){
  for(let attempt=0;attempt<maxAttempts;attempt++){
    await sleep(intervalMs);
    const nextBuildId=await fetchBuildId(path);
    if(nextBuildId&&previousBuildId&&nextBuildId!==previousBuildId){
      return {updated:true,buildId:nextBuildId};
    }
  }
  return {updated:false,buildId:null};
}

export function createBuildSync({
  element,
  path='/admin',
  buildingText='網站重新建置中…',
  doneText='網站已更新',
  pendingText='建置狀態待確認'
}={}){
  let revision=0;

  const setStatus=(text,state)=>{
    if(!element)return;
    element.textContent=text;
    element.dataset.state=state||'';
    element.hidden=!text;
  };

  return async function track(previousBuildId){
    const token=++revision;
    setStatus(buildingText,'building');
    const result=await waitForRebuild(previousBuildId,{path});
    if(token!==revision)return {...result,superseded:true};
    if(result.updated)setStatus(doneText,'done');
    else setStatus(pendingText,'pending');
    return result;
  };
}
