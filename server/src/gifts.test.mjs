import test from 'node:test';
import assert from 'node:assert/strict';
import {FinancialLedgerService} from './modules/finance/ledger.service.mjs';

test('gift debits once, balances both currencies, survives reload, rejects overspend and replay tampering',()=>{
  let state;
  const storage={load:()=>state,save:value=>{state=structuredClone(value);}};
  const ledger=new FinancialLedgerService({storage});
  // Test fixture represents an existing funded account, never a public credit API.
  ledger.entries=[{accountId:'sender',currency:'COINS',entryType:'CREDIT',amount:100}];
  const request={senderId:'sender',recipientId:'receiver',giftId:'rose',roomId:'r1',idempotencyKey:'gift_request_1'};
  const result=ledger.sendGift(request);
  assert.equal(ledger.getBalance('sender'),90);
  assert.equal(ledger.getBalance('receiver','DIAMONDS'),5);
  assert.equal(ledger.sendGift(request).idempotentReplay,true);
  const restored=new FinancialLedgerService({storage});
  assert.equal(restored.sendGift(request).transactionGroup,result.transactionGroup);
  assert.equal(restored.getBalance('sender'),90);
  assert.throws(()=>restored.sendGift({...request,recipientId:'other'}),{statusCode:409});
  assert.throws(()=>restored.sendGift({...request,giftId:'crown',idempotencyKey:'request_two'}),{statusCode:409});
  assert.throws(()=>restored.sendGift({...request,giftId:'__proto__',idempotencyKey:'request_three'}));
  assert.throws(()=>restored.sendGift({...request,recipientId:'sender',idempotencyKey:'request_four'}),{statusCode:400});
  for(const currency of ['COINS','DIAMONDS']) {
    const added=restored.entries.slice(1).filter(e=>e.currency===currency).reduce((sum,e)=>sum+(e.entryType==='CREDIT'?e.amount:-e.amount),0);
    assert.equal(added,0);
  }
});

test('failed persistence exposes no gift or balance mutation',()=>{
  const ledger=new FinancialLedgerService({storage:{load:()=>null,save:()=>{throw new Error('disk unavailable');}}});
  ledger.entries=[{accountId:'sender',currency:'COINS',entryType:'CREDIT',amount:100}];
  assert.throws(()=>ledger.sendGift({senderId:'sender',recipientId:'receiver',giftId:'rose',roomId:'r1',idempotencyKey:'request_1'}));
  assert.equal(ledger.getBalance('sender'),100);
  assert.equal(ledger.idempotencyCache.size,0);
});
