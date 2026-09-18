import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/features/coach/proposal_copy.dart';

void main() {
  test('proposal labels describe their different outcomes', () {
    expect(ProposalCopy.targetTitle, 'Target kata');
    expect(ProposalCopy.targetAccept, 'Terima sebagai misi');
    expect(ProposalCopy.phraseTitle, 'Frasa audio');
    expect(ProposalCopy.phraseAccept, 'Tambah ke papan');
    expect(ProposalCopy.reject, 'Tidak dipakai');
  });

  test('waiting labels keep proposal types distinct', () {
    expect(
      ProposalCopy.targetWaiting(2),
      '2 target kata dari terapis menunggu keputusan',
    );
    expect(
      ProposalCopy.phraseWaiting(1, 'Bu Rina'),
      'Frasa audio dari Bu Rina menunggu keputusan',
    );
    expect(
      ProposalCopy.phraseWaiting(3, 'Bu Rina'),
      '3 frasa audio menunggu keputusan',
    );
  });
}
