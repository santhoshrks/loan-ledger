import 'p2p_repository.dart';
import 'p2p_repository_local.dart';
import 'p2p_repository_remote.dart';

enum P2PDataSource { local, remote }

class P2PRepositoryFactory {
  static P2PRepository create({P2PDataSource source = P2PDataSource.local}) {
    switch (source) {
      case P2PDataSource.remote:
        return P2PRepositoryRemote();
      case P2PDataSource.local:
        return P2PRepositoryLocal();
    }
  }
}
