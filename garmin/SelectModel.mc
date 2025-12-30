import Toybox.Lang;

class SelectModel {
    private var _selectedTrack as Number = 0;

    public function setSelectedTrack(track as Number) as Void {
        _selectedTrack = track;
    }

    public function getSelectedTrack() as Number {
        return _selectedTrack;
    }
}
