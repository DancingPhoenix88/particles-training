using UnityEditor;
using UnityEngine;

public class GameObjectToggle : Editor {
    [MenuItem("GameObject/Toggle GameObjects _ ")]
    static void ToggleActivationSelection() {
        bool gotFirstState = false;
        bool state         = true;
        foreach (GameObject go in Selection.gameObjects) {
            if (!gotFirstState) {
                state = !go.activeSelf;
                gotFirstState = true;
            }
            go.SetActive( state );
        }
    }
}