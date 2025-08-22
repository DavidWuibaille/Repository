<?php
function wakeOnLan($broadcastAddress, $macAddress) {
    $macAddress = str_replace([':', '-'], '', $macAddress);
    $magicPacket = str_repeat(chr(255), 6) . str_repeat(pack('H12', $macAddress), 16);

    if (!($sock = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP))) {
        return "Cannot create socket";
    }

    $options = socket_set_option($sock, SOL_SOCKET, SO_BROADCAST, 1);
    if (!$options) {
        socket_close($sock);
        return "Failed to set socket option";
    }

    $send = socket_sendto($sock, $magicPacket, strlen($magicPacket), 0, $broadcastAddress, 9);
    socket_close($sock);

    if (!$send) {
        return "Failed to send magic packet";
    }

    return "Wake-on-LAN packet has been sent to $macAddress.";
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($_POST['mac'])) {
    echo wakeOnLan('192.168.0.255', $_POST['mac']);
} else {
    echo "Invalid request";
}
?>
