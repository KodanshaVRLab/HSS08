using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public interface IRythmicObject 
{
    bool beatInteraction(beat currentBeat, float starttime, RythmReplay.rythmState RState);

}
