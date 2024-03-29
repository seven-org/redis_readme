# mysql,redis如何保证双写一致性

对于双写一致性问题，主要矛盾就在于：
    1. 更新完数据库是更新缓存还是删除缓存
    2. 就删除缓存而言，是先删缓存还是先更新数据库

解决方案：缓存设置过期时间【方案1】：缓存设置过期时间是保持最终一致性的方案，但并不能保证强一致性。缓存过期后，再次获取缓存时会走数据库，获取到后再更新缓存 接下来讨论下述三种情况

1. **先更新数据库，再更新缓存** 
这种做法实际上是**不可取**的，因为不能保证线程安全。比如现在线程A更新了数据库，还没更新缓存时，线程B更新了同一数据，并且更新了缓存，之后线程A又把缓存更新为A的了，从时效上来看，A先来B后来，最后要保留的应该是B的更新，这就出现了问题。
其次从业务角度出发，如果业务场景是写操作更多的，就会导致数据还没读到缓存就被更新了，频繁的更新导致性能浪费。
综上而言，删除缓存更加合适。每次获取缓存的时候如果没有，就走数据库，然后再将获取到的数据库的值更新到缓存中

2. **先删除缓存，再更新数据库**
会导致脏读：如果线程A进行写操作，删除缓存，还没更新数据库时，线程B来查询了这条数据，因为缓存被删除，就去查数据库，得到了旧值并且更新到缓存中，之后线程A又把新值写入数据库，之后来查这个数据的线程拿到的都是旧数据，也就产生了脏读，要如何解决这个问题呢？
因为线程B查询到旧数据又把旧数据更新到缓存中了，而线程A一开始就把缓存删除了，之后如果线程A还能把线程B设置的旧数据缓存给删掉，脏读问题就解决了
所以引入了延时双删策略【方案2】，即更新数据时：**先删除缓存、更新数据库、延时（让线程B有足够的时候把旧数据放到缓存里，确保后续二次删除时删除的是在读操作产生的脏数据，也就是说这个延时的时间应该是读操作的耗时+几百ms）、再删除缓存**
当然延时本身会导致时间消耗，降低吞吐量，因此可以新开一个线程来异步延时删除，也就是延时异步双删策略【方案3】
但是就这样仍然会存在问题，就是如果第二次删除失败怎么办？
解决办法就是建立重试机制：
一是可以把删除失败的key放到消息队列中，单写一个接收消息的方法来不断尝试删除key直到成功【方案4】
二是通过订阅数据库的binlog，获得需要操作的数据，在应用程序中单写方法来获得订阅程序传来的消息来删除缓存，订阅binlog可以使用mysql自带的canal来实现【方案5】

3. **先更新数据库，再删除缓存**【方案6】
国外一些公司像facebook提出的就是先更新数据库再删除的策略，具体是：
从缓存拿数据，没有得到，就走数据库，拿到后再更新到缓存一份 
从缓存拿数据，有就直接返回，把数据更新到数据库，然后删除缓存
针对这种做法，出现线程不安全的情形其实就只有一个：
线程A查询数据，发现缓存中没有，就从数据库拿
还没来得及将拿到的值更新一份到缓存时，线程B来更新数据，先将值更新到数据库，然后删除缓存
等线程B删除缓存后，线程A才将旧值更新到缓存上，这样后续线程就产生了脏读
但是针对这一问题的概率需要做讨论：
要让线程B在线程A更新缓存前把缓存删除，就得要求线程B写入数据库的操作比线程A查询数据库的速度更快，这样就能先发起线程B删除缓存，但是实际上读操作是比写操作要快得多的，所以这类问题发生的概率很小很小，但是如果一定要考究的话，那么就参考上述的延时异步双删策略最后延时再删除一遍缓存，将读操作产生的旧数据缓存删掉



